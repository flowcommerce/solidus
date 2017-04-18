require 'flowcommerce'
require 'thread/pool'
require 'digest/sha1'

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
      count      = tiers.select{ |tier| tier.experience.id == exp.key }.length
      count_desc = count == 0 ? '0 (error!)'.red : count.to_s.green
      puts ' Experience %s has %s devivery tiers defined' % [exp.key.yellow, count_desc]
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

      country_id = experience.country.downcase
      page_size  = 100
      offset     = 0
      items      = []

      while offset == 0 || items.length == 100
        # show current list size
        puts "\nGetting items: %s, rows %s - %s" % [country_id.upcase.green, offset, offset + page_size]

        # items = Flow.api(:get, '/:organization/experiences/items', country: country_id, limit: country_id, offset: offset)
        items = FlowCommerce.instance.experiences.get_items Flow.organization, :country => country_id, :limit => page_size, :offset => offset

        offset += page_size

        items.each do |item|

          total += 1
          sku        = item.number.downcase
          variant    = Spree::Variant.find sku.split('-').last.to_i
          next unless variant

          variant.flow_import_item item

          print '%s, ' % sku
        end
      end
    end

    puts 'Finished with total of %s rows.' % total.to_s.green
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
  end
end

