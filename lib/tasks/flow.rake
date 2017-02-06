# uploads catalog to flow api
# using local database

require 'thread/pool'

namespace :flow do
  desc 'Upload catalog'
  task upload_catalog: :environment do

    variants = Spree::Variant.limit(50).all

    # do reqests in paralel
    thread_pool = Thread.pool(5)

    variants.each_with_index do |variant, i|
      product = variant.product

      # our id
      sku = variant.sku

      data = {}
      data[:locale]      = 'en_US'
      data[:number]      = sku
      data[:name]        = product.name
      data[:description] = product.description
      data[:price]       = variant.cost_price.to_f
      data[:currency]    = variant.cost_currency
      data[:images]      = [
        { url: product.display_image.attachment(:product), tags: ['main'] },
        { url: product.images.first.attachment.url(:mini), tags: ['thumbnail'] }
      ]
      # data[:categories]  = ['Foo', 'Bar']

      json = data.to_json

      # use curl for uploading insted of Ruby Net, more reliabe
      url  = "https://api.flow.io/#{ENV.fetch('FLOW_ORG')}/catalog/items/#{sku}"
      curl = %[curl -s -X PUT -H "Content-Type: application/json" -u #{ENV.fetch('FLOW_API_KEY')}: -d '#{json}' "#{url}"]

      thread_pool.process do
        puts "#{i.to_s.rjust(3)}. #{sku}: #{product.name}"
        response = `#{curl}`
        # ap JSON.parse(response)
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

    Pathname.new('./config/flow_experiences.yml').write(data.to_yaml)
  end
end

