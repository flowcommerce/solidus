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
    flow_client   = FlowCommerce.instance
    flow_org      = ENV.fetch('FLOW_ORG')

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
        product       = variant.product
        sku           = variant.id.to_s
        flow_item     = variant.flow_api_item
        flow_item_sh1 = Digest::SHA1.hexdigest flow_item.to_json

        # skip if sync not needed
        if variant.flow_cache['last_sync_sh1'] == flow_item_sh1
          print '.'
          next
        end

        update_sum += 1

        # multiprocess upload
        thread_pool.process do
          flow_client.items.put_by_number flow_org, sku, flow_item

          # after successful put, write cache
          variant.update_column :flow_cache,  flow_cache.merge('last_sync_sh1'=>flow_item_sh1)

          puts "\n%s: %s (%s %s)" % [sku, product.name, variant.price, variant.cost_currency]
        end
      end
    end

    thread_pool.shutdown

    puts "\nFor total of %s products, %s needed update" % [total_sum.to_s.blue, (update_sum == 0 ? 'none' : update_sum).to_s.green]
  end

  desc 'Gets and cache experiences from flow'
  task check: :environment do
    required_env_variables = ['FLOW_TOKEN', 'FLOW_ORG', 'FLOW_BASE_COUNTRY']
    required_env_variables.each { |el| puts 'ENV: %s - %s ' % [el, ENV[el].present? ? 'present'.green : 'MISSING'.red]  }

    puts 'Getting experiences for flow org: %s' % ENV.fetch('FLOW_ORG')
    client   = FlowCommerce.instance
    api_data = client.experiences.get(ENV.fetch('FLOW_ORG'))
    puts 'Got %d experinences - %s'.green % [api_data.length, api_data.map(&:country).join(', ')]
  end

  desc 'Sync localized catalog items'
  task :sync_localized_items => :environment do |t|
    # https://api.flow.io/reference/countries
    # https://docs.flow.io/#/module/localization/resource/experiences

    total = 0

    org = ENV.fetch('FLOW_ORG')
    experiences = FlowCommerce.instance.experiences.get(org)

    experiences.each do |experience|

      country_id = experience.country.downcase
      page_size  = 100
      offset     = 0
      items      = []

      while offset == 0 || items.length == 100
        # show current list size
        puts "\nGetting items: %s, rows %s - %s" % [country_id.upcase.green, offset, offset + page_size]

        # items = Flow.api(:get, '/:organization/experiences/items', country: country_id, limit: country_id, offset: offset)
        items = FlowCommerce.instance.experiences.get_items org, :country => country_id, :limit => page_size, :offset => offset

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
          puts 'Removed item: %s' % sku.red
        end
      end
    end

    thread_pool.shutdown
  end

  desc 'Ensure we have DB prepared for flow'
  task :migrate => :environment do |t|
    # FlowExperience.all.each do |exp|
    #   zone = Spree::Zone.find_by name: exp.key
    #   raise 'Spree::Zone "%s" is not defiend'.red % exp.key unless zone
    #   puts 'Spree::Zone name:"%s" found'.green % zone.name
    # end

    migrate = []
    migrate.push [:spree_orders, :flow_number, :string]
    migrate.push [:spree_orders,  :flow_cache, :jsonb, default: {}]
    migrate.push [:spree_variants, :flow_cache, :jsonb, default: {}]

    migrate.each do |table, field, type, opts={}|
      klass = table.to_s.sub('spree_','spree/').classify.constantize

      if klass.new.respond_to?(field)
        puts 'Field %s in table %s exists'.green % [field, table]
      else
        ActiveRecord::Migration.add_column table, field, type, opts
        puts 'Field %s in table %s added'.green % [field, table]
      end
    end
  end
end

