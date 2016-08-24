require "smarter_csv"

namespace :import do
  namespace :csv do
    desc "Import products from CSV"
    task products: :environment do
      csv_file = ARGV.last
      task csv_file.to_sym {}
      rows = SmarterCSV.process(csv_file)

      rows.each do |row|
        Import::ProductImporter.new(row).import
      end
    end

    desc "Import variants from CSV"
    task variants: :environment do
      csv_file = ARGV.last
      task csv_file.to_sym {}
      rows = SmarterCSV.process(csv_file)

      rows.each do |row|
        spree_product = Spree::Variant.find_by(sku: row[:product_sku]).product
        Import::VariantImporter.new(spree_product, row).import
      end
    end

    # TODO: products and variants in one go, so we don't expose products without variants
  end
end
