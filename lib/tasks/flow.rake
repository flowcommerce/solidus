
require 'flowcommerce'
require 'thread/pool'

namespace :flow do
  # uploads catalog to flow api
  # using local solidus database
  # run like 'rake flow:upload_catalog[:force]'
  # if you want to force update all products
  desc 'Upload catalog'
  task :upload_catalog, [:force] => :environment do |t, args|

    flow_client   = FlowCommerce.instance
    flow_org      = ENV.fetch('FLOW_ORG')

    # do reqests in paralel
    thread_pool = Thread.pool(5)
    total_sum   = 0

    variants = Spree::Variant.order('updated_at desc').limit(10_000).all

    variants.each_with_index do |variant, i|
      product = variant.product

      image_base = 'http://cdn.color-mont.com'

      sku   = variant.flow_number
      price = variant.cost_price.to_f
      price = product.price.to_f if price == 0

      # skip sync if allready synced to last price
      next if !args[:force] && variant.flow_cache['last_sync_price'] == price

      total_sum += 1

      flow_item = Io::Flow::V0::Models::ItemForm.new(
        number:      sku,
        locale:      'en_US',
        language:    'en',
        name:        product.name,
        description: product.description,
        currency:    variant.cost_currency,
        price:       price,
        images: [
          { url: image_base + product.display_image.attachment(:large), tags: ['main'] },
          { url: image_base + product.images.first.attachment.url(:product), tags: ['thumbnail'] }
        ]
      )

      # multiprocess upload
      thread_pool.process do
        puts '%s. %s: %s (%s $)' % [i.to_s.rjust(3), sku, product.name, price]

        # response = Flow.api :put, '/:organization/catalog/items/%s' % sku, BODY: flow_item.to_hash
        # https://github.com/flowcommerce/ruby-sdk/blob/master/examples/create_items.rb
        flow_client.items.put_by_number flow_org, sku, flow_item

        # after successful put, write cache
        variant.flow_cache['last_sync_price'] = price
        variant.save
      end
    end

    puts 'For total if %s products, %s needed update' % [variants.length.to_s.blue, (total_sum == 0 ? 'none' : total_sum).to_s.green]

    thread_pool.shutdown
  end

  desc 'Gets and cache experiences from flow'
  task get_experiences: :environment do
    puts 'Getting experiences for flow org: %s' % ENV.fetch('FLOW_ORG')

    client   = FlowCommerce.instance
    api_data = client.experiences.get(ENV.fetch('FLOW_ORG'))

    puts 'Saved %d experinences - %s'.green % [api_data.length, api_data.map(&:country).join(', ')]

    Pathname.new(Flow::EXPERIENCES_PATH).write(api_data.map(&:to_hash).to_yaml)
  end

  desc 'Get localized catalog items'
  task :precache_catalog_items, [:clean]=> :environment do |t, args|
    # https://api.flow.io/reference/countries
    # https://docs.flow.io/#/module/localization/resource/experiences

    if args[:clean]
      # clean complete product catalog from cache
      Spree::Variant.all.each { |v| v.update_column :flow_cache, {};'' }
    end

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
        puts 'Getting items: %s, rows %s - %s' % [country_id.upcase.green, offset, offset + page_size]

        # items = Flow.api(:get, '/:organization/experiences/items', country: country_id, limit: country_id, offset: offset)
        items = FlowCommerce.instance.experiences.get_items org, :country => country_id, :limit => page_size, :offset => offset

        offset += page_size

        items.each do |item|

          total += 1
          sku        = item.number.downcase
          variant    = Spree::Variant.find sku.split('-').last.to_i
          next unless variant

          variant.import_flow_item item

          puts sku
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

        do_remove = if sku.include?('s-variant-')
          variant_id = sku.split('s-variant-').last.to_i
          do_remove = Spree::Variant.find(variant_id) ? false : true
        else
          true
        end

        next unless do_remove

        thread_pool.process do
          Flow.api :delete, '/:organization/catalog/items/%s' % sku
          puts 'Removed item: %s' % sku.red
        end
      end
    end

    thread_pool.shutdown
  end
end

