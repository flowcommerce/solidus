
require 'flowcommerce'
require 'thread/pool'

namespace :flow do
  # uploads catalog to flow api
  # using local solidus database
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

      body = data.to_json

      # multiprocess upload
      thread_pool.process do
        puts '%s. %s: %s (%s $)' % [i.to_s.rjust(3), sku, product.name, data[:price]]

        # https://github.com/flowcommerce/ruby-sdk/blob/master/examples/create_items.rb
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
          sku    = item.number

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

