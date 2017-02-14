# uploads catalog to flow api
# using local database

require 'flowcommerce'
require 'thread/pool'

namespace :flow do
  desc 'Upload catalog'
  task upload_catalog: :environment do

    variants = Spree::Variant.limit(1000).all

    # do reqests in paralel
    thread_pool = Thread.pool(5)

    variants.each_with_index do |variant, i|
      product = variant.product

      image_base = 'http://cdn.color-mont.com'

      # our id
      sku = variant.sku

      data = {}
      data[:locale]      = 'en_US'
      data[:number]      = sku
      data[:name]        = product.name
      data[:description] = product.description
      data[:currency]    = variant.cost_currency
      data[:images]      = [
        { url: image_base + product.display_image.attachment(:large), tags: ['main'] },
        { url: image_base + product.images.first.attachment.url(:product), tags: ['thumbnail'] }
      ]

      data[:price] = variant.cost_price.to_f
      data[:price] = product.price.to_f if data[:price] == 0

      unless data[:price]
        ap data
        exit
      end

      # data[:categories]  = ['Foo', 'Bar']

      body = data.to_json

      # multiprocess upload
      thread_pool.process do
        puts '%s. %s: %s (%s $)' % [i.to_s.rjust(3), sku, product.name, data[:price]]

        response = Flow.api :put, '/:organization/catalog/items/%s' % sku, BODY: body
        if response['code'] == 'generic_error'
          ap response
          ap data
          puts data.to_json
        end
      end
    end

    thread_pool.shutdown
  end

  desc 'Gets experiences from flow'
  task get_experiences: :environment do
    puts 'Getting experiences for flow org: %s' % ENV.fetch('FLOW_ORG')

    client   = FlowCommerce.instance
    api_data = client.experiences.get(ENV.fetch('FLOW_ORG'))

    puts 'Saved %d experinences - %s'.green % [api_data.length, api_data.map(&:country).join(', ')]

    Pathname.new(Flow::EXPERIENCES_PATH).write(api_data.map(&:to_hash).to_yaml)
  end

  desc 'get catalog items'
  task get_catalog_items: :environment do
    # https://api.flow.io/reference/countries
    # https://docs.flow.io/#/module/localization/resource/experiences

    client        = FlowCommerce.instance
    api_data      = client.experiences.get(ENV.fetch('FLOW_ORG'))
    country_codes = api_data.map(&:country).map(&:downcase)

    for country_id in country_codes
      page_size  = 100
      offest     = 0
      data = []

      while offest == 0 || data.length == 100
        puts '%s : %s - %s' % [country_id, offest, offest + page_size]

        data = Flow.api(:get, '/:organization/experiences/items', country: country_id, limit: page_size, offset: offest)

        offest += page_size

        data.each do |row|
          local     = row['local']
          sku       = row['number'].downcase
          remote_id = local['experience']['id']
          country   = country_id.downcase

          # fill the catalog
          fcc = FlowCatalogCache.find_or_initialize_by sku: sku, country: country
          fcc.remote_id = remote_id
          fcc.data = local
          fcc.save!

          puts sku
        end
      end
    end
  end
end

