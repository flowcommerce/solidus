# imports products and variants to Solidus product catalog
# http://guides.spreecommerce.org/developer/products.html

# how to import products to spree / solidus, the right way
# req: you have to have at least sku, name, description, price and image
# * create product with sku, name, description and price
# * variant master will automaticly be addded
# * with variant id, create product image
# * done!

require './lib/import/custom_products'
require './lib/import/solidus_db'

# TODO: products and variants in one go, so we don't expose products without variants on a live site
namespace :import do

  # rake import:csv:products tmp/data.csv
  namespace :csv do
    desc 'Import products from CSV'
    task products: :environment do
      csv_source = ARGV.second

      puts 'CSV not defined as argument'.red unless csv_source
      puts 'CSV file not found'.red unless File.exist?(csv_source)

      # init db
      # %w[S M L XL XXL XXXL].each { |size|  Import::SolidusDb.create_variant('size', size) }
      # %w[Black Brown Green].each { |color| Import::SolidusDb.create_variant('color', color) }

      csv = Import::CustomProducts.new csv_source
      puts "Total of #{csv.count} rows present for import"

      cnt = 0
      while row = csv.get_row
        next unless row

        cnt += 1
        # every product is a dot in a console

        ap row

        puts "%{name} (size: %{size}, color: %{color})" % row

        Import::SolidusDb.call row

        # exit if ++cnt > 10
      end
    end
  end

end
