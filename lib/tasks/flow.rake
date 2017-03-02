
require 'flowcommerce'
require 'thread/pool'

namespace :flow do
  # uploads catalog to flow api
  # using local solidus database
  desc 'Upload catalog'
  task upload_catalog: :environment do

    flow_client   = FlowCommerce.instance
    flow_org      = ENV.fetch('FLOW_ORG')

    # do reqests in paralel
    thread_pool = Thread.pool(5)

    variants = Spree::Variant.limit(1000).all

    variants.each_with_index do |variant, i|
      product = variant.product

      image_base = 'http://cdn.color-mont.com'

      # our id
      sku   = variant.sku.downcase
      price = variant.cost_price.to_f
      price = product.price.to_f if price == 0

      flow_item = Io::Flow::V0::Models::ItemForm.new(
        number:      sku,
        locale:      'en_US',
        name:        product.name,
        description: product.description,
        currency:    variant.cost_currency,
        price:       99.99,
        language:    'en',
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
      end
    end

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
  task get_catalog_items: :environment do
    # https://api.flow.io/reference/countries
    # https://docs.flow.io/#/module/localization/resource/experiences

    total = 0

    org = ENV.fetch('FLOW_ORG')
    experiences = FlowCommerce.instance.experiences.get(org)

    experiences.each do |experience|
      country_id = experience.country.downcase
      page_size  = 100
      offest     = 0
      items      = []

      while offest == 0 || items.length == 100
        # show current list size
        puts 'Getting items: %s, rows %s - %s' % [country_id.upcase.green, offest, offest + page_size]

        # items = Flow.api(:get, '/:organization/experiences/items', country: country_id, limit: country_id, offset: offest)
        items = FlowCommerce.instance.experiences.get_items org, :country => country_id, :limit => page_size, :offset => offest

        offest += page_size

        items.each do |item|
          total += 1
          sku    = item.number.downcase

          # fill the catalog
          fcc           = FlowCatalogCache.find_or_initialize_by sku: sku, country: country_id
          fcc.remote_id = item.id
          fcc.data      = item.to_hash
          fcc.save!

          puts sku
        end
      end
    end

    puts 'Finished with total of %s rows.' % total.to_s.green
  end
end

