require "smarter_csv"
require "open-uri"

def uri?(string)
  uri = URI.parse(string)
  %w( http https ).include?(uri.scheme)
rescue URI::BadURIError
  false
rescue URI::InvalidURIError
  false
end

def download_file(csv_file_or_url, tmp_file_name = "download.txt")
  filepath = "#{Rails.root}/tmp/#{tmp_file_name}.csv"
  download = open(csv_file_or_url)
  IO.copy_stream(download, filepath)
  filepath
end

# TODO: products and variants in one go, so we don't expose products without variants on a live site
# TODO: option to flush existing products, variants and images before import ()
namespace :import do
  namespace :csv do
    desc "Import products from CSV"
    task products: :environment do
      # TODO: error if ARGV doesn't include filename
      source = ARGV.second
      task source.to_sym {}

      item_delimiter = ENV["item_delimiter"] || ","
      key_delimiter = ENV["key_delimiter"] || ":"
      hierarchy_delimiter = ENV["hierarchy_delimiter"] || ">"

      csv_file = if uri?(source)
                   download_file(source, "downloaded_products")
                 else
                   source
                 end

      f = File.open(csv_file, "r:bom|utf-8");
        rows = SmarterCSV.process(f);
      f.close
      #
      # rows = SmarterCSV.process(csv_file)

      import_errors = {}
      rows.each do |row|
        begin
          sku = row[:sku].to_s.to_sym # SKU field might be parsed as a number
          Import::ProductImporter.new(row, item_delimiter: item_delimiter, key_delimiter: key_delimiter).import
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
      source = ARGV.last
      task source.to_sym {}

      csv_file = if uri?(source)
                   download_file(source, "downloaded_variants.csv")
                 else
                   source
                 end

      rows = SmarterCSV.process(csv_file)

      import_errors = {}
      rows.each do |row|
        begin
          sku = row[:sku].to_s.to_sym
          product_sku = row[:product_sku].to_s
          spree_product = Spree::Variant.find_by(sku: product_sku).try(:product)
          raise "Product #{product_sku} doesn't exist yet" unless spree_product.present?
          Import::VariantImporter.new(spree_product, row).import
        rescue => e
          import_errors[sku] = e
          puts "Error importing variant with SKU #{sku}: #{e}"
        end
      end

      if import_errors.count == 0
        puts "Variants imported with no errors"
      else
        puts "Variants imported with #{import_errors.count} errors"
      end
    end

    desc "Test CSV file download"
    task download_test: :environment do
      # TODO: error if ARGV doesn't include filename
      csv_file_or_url = ARGV.last
      task csv_file_or_url.to_sym {}

      if uri?(csv_file_or_url)
        download = open(csv_file_or_url)
        filepath = "#{Rails.root}/tmp/products.csv"
        IO.copy_stream(download, filepath)
        csv_file = filepath
      else
        csv_file = csv_file_or_url
      end
      rows = SmarterCSV.process(csv_file)
    end

  end
end
