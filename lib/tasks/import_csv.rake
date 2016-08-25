require "smarter_csv"

namespace :import do
  namespace :csv do
    desc "Import products from CSV"
    task products: :environment do
      csv_file = ARGV.last
      task csv_file.to_sym {}
      # TODO: process rows in batches
      rows = SmarterCSV.process(csv_file)

      import_errors = {}
      rows.each do |row|
        begin
          sku = row[:sku].to_sym
          Import::ProductImporter.new(row).import
        rescue => e
          import_errors[sku] = e
          puts "Error importing product with SKU #{sku}: #{e}"
        end
      end

      if import_errors.count == 0
        puts "Products imported with no errors"
      else
        puts "Products imported with #{import_errors.count} errors"
      end
    end

    desc "Import variants from CSV"
    task variants: :environment do
      csv_file = ARGV.last
      task csv_file.to_sym {}
      rows = SmarterCSV.process(csv_file)

      import_errors = {}
      rows.each do |row|
        begin
          sku = row[:sku].to_sym
          product_sku = row[:product_sku]
          spree_product = Spree::Variant.find_by(sku: product_sku).try(:product)
          raise "Product #{product_sku} doesn't exist yet" unless spree_product.present?
          Import::VariantImporter.new(spree_product, row).import
        rescue => e
          import_errors[sku] = e
          puts "Error importing variant with SKU #{sku}: #{e}"
        end
      end

      if import_errors.count == 0
        puts "Products imported with no errors"
      else
        puts "Products imported with #{import_errors.count} errors"
      end
    end

    # TODO: print logger output
    # TODO: products and variants in one go, so we don't expose products without variants
  end
end
