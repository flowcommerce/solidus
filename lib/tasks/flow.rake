require 'flowcommerce'
require 'thread/pool'
require 'digest/sha1'

desc 'lists all flow tasks'
task :flow do |t|
  command = 'rake -T | grep flow'
  puts '    %s' % command
  puts '    -'

  tasks = `#{command}`.split($/)

  tasks.shift # first task is this on, rake flow

  tasks.each_with_index do |task, index|
    puts ' %d. %s' % [index + 1, task]
  end

  puts '    -'
  print 'Task number: '
  task = $stdin.gets.to_i
  task = tasks[task - 1].to_s.split(/\s+/)[1]

  if task.present?
    puts 'Executing: %s' % task
    Rake::Task[task].invoke
  else
    puts 'task not found'.red
  end
end

namespace :flow do
  # uploads catalog to flow api
  # using local solidus database
  # run like 'rake flow:upload_catalog[:force]'
  # if you want to force update all products
  desc 'Upload catalog'
  task :upload_catalog => :environment do |t|
    # do reqests in paralel
    thread_pool  = Thread.pool(5)
    update_sum   = 0
    total_sum    = 0
    current_page = 0
    variants     = []

    while current_page == 0 || variants.length > 0
      current_page += 1
      variants = Spree::Variant.order('updated_at desc').page(current_page).per(100).all

      variants.each_with_index do |variant, i|
        total_sum    += 1

        # multiprocess upload
        thread_pool.process do
          # skip if sync not needed
          if variant.flow_sync_product
            update_sum += 1
            $stdout.print "\n%s: %s (%s %s)" % [variant.id.to_s, variant.product.name, variant.price, variant.cost_currency]
          else
            $stdout.print '.'
          end
        end
      end
    end

    thread_pool.shutdown

    puts "\nFor total of %s products, %s needed update" % [total_sum.to_s.blue, (update_sum == 0 ? 'none' : update_sum).to_s.green]
  end

  desc 'Check if ENV vars, center and tier per experience is set'
  task check: :environment do
    puts 'Environment check'
    required_env_variables = ['FLOW_API_KEY', 'FLOW_ORGANIZATION', 'FLOW_BASE_COUNTRY']
    required_env_variables.each { |el| puts ' ENV: %s - %s ' % [el, ENV[el].present? ? 'present'.green : 'MISSING'.red]  }

    # experiences
    puts 'Experiences:'
    puts ' Getting experiences for flow org: %s' % Flow.organization
    client      = FlowCommerce.instance
    experiences = client.experiences.get(Flow.organization)
    puts ' Got %d experinences - %s'.green % [experiences.length, experiences.map(&:country).join(', ')]

    # create detault experience unless one exists
    puts 'Centers:'
    center_name     = 'default'
    current_cetners = client.centers.get(Flow.organization).map(&:key)
    if current_cetners.include?(center_name)
      puts ' Default center: %s' % 'present'.green
    else
      Flow.api :put, '/:organization/centers/%s' % center_name, {}, {'key':center_name,'address':{'contact':{'name':{'first':'Kinto','last':'Doe'},'company':'XYZ Corporation, Inc','email':'dcone@test.flow.io','phone':'1-555-444-0001'},'location':{'streets':['88 East Broad Street'],'city':'Columbus','province':'OH','postal':'43215','country':'USA'}},'packaging':[{'dimensions':{'packaging':{'depth':{'value':'9','units':'inch'},'length':{'value':'13','units':'inch'},'weight':{'value':'1','units':'pound'},'width':{'value':'3','units':'inch'}}},'name':'Big Box','number':'box1'}],'name':'Solidus Test','services':[{'service':'dhl-express-worldwide'},{'service':'landmark-global'}],'schedule':{'holiday':'us_bank_holidays','exception':[{'type':'closed','datetime_range':{'from':'2016-05-05T18:30:00.000Z','to':'2016-05-06T18:30:00.000Z'}}],'calendar':'weekdays','cutoff':'16:30'},'timezone':'US/Eastern'}
      puts ' Default center: %s (run again)' % 'created'.blue
    end

    # tiers
    puts 'Tiers:'
    tiers = FlowCommerce.instance.tiers.get(Flow.organization)
    experiences.each do |exp|
      exp_tiers    = tiers.select{ |tier| tier.experience.id == exp.key }
      count        = exp_tiers.length
      count_desc   = count == 0 ? '0 (error!)'.red : count.to_s.green
      print ' Experience %s has %s devivery tiers defined, ' % [exp.key.yellow, count_desc]

      exp_services = exp_tiers.inject([]) { |total, tier| total.push(*tier.services.map(&:id)) }
      if exp_services.length == 0
        puts 'and no delivery services defined!'.red
      else
        puts 'with %s devlivery services defined (%s)' % [exp_services.length.to_s.green, exp_services.join(', ')]
      end
    end

    # default URL
    puts 'Default store URL:'
    url = Spree::Store.find_by(default:true).url
    puts ' Spree::Store.find_by(default:true).url == "%s" (ensure this is valid and right URL)' % url.blue
  end

  desc 'Sync localized catalog items'
  task :sync_localized_items => :environment do |t|
    # https://api.flow.io/reference/countries
    # https://docs.flow.io/#/module/localization/resource/experiences

    total = 0

    experiences = FlowCommerce.instance.experiences.get(Flow.organization)

    experiences.each do |experience|
      page_size  = 100
      offset     = 0
      items      = []

      while offset == 0 || items.length == 100
        # show current list size
        puts "\nGetting items: %s, rows %s - %s" % [experience.key.green, offset, offset + page_size]

        items = FlowCommerce.instance.experiences.get_items Flow.organization, experience: experience.key, limit: page_size, offset: offset

        offset += page_size

        items.each do |item|
          total += 1
          sku        = item.number.downcase
          variant    = Spree::Variant.find sku.split('-').last.to_i
          next unless variant

          # if item is not included, mark it in product as excluded
          # regardles if excluded or restricted
          unless item.local.status.value == 'included'
            print '[%s]:' % item.local.status.value.red
            product = variant.product
            product.flow_cache['%s.excluded' % experience.key] = 1
            product.update_column :flow_cache, product.flow_cache.dup
          end

          variant.flow_import_item item

          print '%s, ' % sku
        end
      end
    end

    puts 'Finished with total of %s rows.' % total.to_s.green
  end

  desc 'Sync restricted products'
  task :sync_restricted_products => :environment do |t|
    page_size  = 25
    offset     = 0
    total      = 0
    products   = {}
    flow_data  = []

    while offset == 0 || flow_data.length == page_size
      flow_data = Flow.api :get, '/:organization/item-restrictions', offset: offset, page_size: page_size
      offset += page_size
      total  += flow_data.length

      # build hash of restricted products
      #  key is experience id
      #  value is array of restricted products
      flow_data.each do |item|
        number = item['item']['number']
        item['regions'].each do |region|
          products[region['id']] ||= []
          products[region['id']].push number.to_i
        end
      end
    end

    products.each do |experience_id, list_of_restricted_products|
      flow_option = FlowOption.find_or_initialize_by(experience_region_id: experience_id)
      flow_option.restricted_ids = list_of_restricted_products
      flow_option.save!
    end

    puts 'Added total of %s restricted products from Flow' % total.to_s.blue
  end

  # checks existance of every item in local produt catalog
  # remove product from flow unless exists localy
  desc 'Remove unused items from flow catalog'
  task clean_catalog: :environment do

    page_size  = 100
    offset     = 0
    items      = []

    thread_pool = Thread.pool(5)

    while offset == 0 || items.length == 100
      items = Flow.api :get, '/:organization/catalog/items', limit: page_size, offset: offset
      offset += page_size

      items.each do |item|
        sku = item['number']

        do_remove = false
        do_remove = true if sku.to_i == 0 || sku.to_i.to_s != sku
        do_remove = true if !do_remove && !Spree::Variant.find(sku.to_i)

        next unless do_remove

        thread_pool.process do
          Flow.api :delete, '/:organization/catalog/items/%s' % sku
          $stdout.puts 'Removed item: %s' % sku.red
        end
      end
    end

    thread_pool.shutdown
  end

  desc 'Ensure we have DB prepared for flow'
  task :migrate => :environment do |t|
    # Flow::Experience.all.each do |exp|
    #   zone = Spree::Zone.find_by name: exp.key
    #   raise 'Spree::Zone "%s" is not defiend'.red % exp.key unless zone
    #   puts 'Spree::Zone name:"%s" found'.green % zone.name
    # end

    migrate = []
    migrate.push [:spree_orders, :flow_number, :string]
    migrate.push [:spree_credit_cards, :flow_cache, :jsonb, default: {}]
    migrate.push [:spree_products,     :flow_cache, :jsonb, default: {}]
    migrate.push [:spree_variants,     :flow_cache, :jsonb, default: {}]
    migrate.push [:spree_orders,       :flow_cache, :jsonb, default: {}]

    migrate.each do |table, field, type, opts={}|
      klass = table.to_s.sub('spree_','spree/').classify.constantize

      if klass.new.respond_to?(field)
        puts 'Field %s in table %s exists'.green % [field, table]
      else
        ActiveRecord::Migration.add_column table, field, type, opts
        puts 'Field %s in table %s added'.blue % [field, table]
      end
    end

    if FlowOption.table_exists?
      puts 'Table flow_options exists'.green
    else
      ActiveRecord::Migration.create_table :flow_options do |t|
        t.string  :experience_region_id
        t.integer :restricted_ids, array: true, default: []
      end
    end
  end
end

