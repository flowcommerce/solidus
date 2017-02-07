# uploads catalog to flow api
# using local database

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

        response = Flow.remote :put, '/:organization/catalog/items/%s' % sku, BODY: body
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

    data = Flow.remote :get, '/:organization/experiences'

    # we will remove id and subcatalog from response because we do not need it
    data.each { |list_el|
      [:id, :subcatalog].each { |key|
        list_el.delete(key.to_s)
      }
    }

    Pathname.new(FLOW::EXPERIENCES_PATH).write(data.to_yaml)
  end
end

