module Import
  module Intermediates
    # Intermediate product for importing/exporting
    class Variant
      # TODO: document structure of @attributes
      def initialize(attributes, key_to_match = :name)
        @attributes = attributes
        @key_to_match = key_to_match
      end

      attr_reader :key_to_match

      def self.from_csv_attributes(attributes, key_to_match = :name)
        new(attributes, key_to_match)
      end

      # Massage source product data into spree product data
      # If we're updating an existing product, we need it as an argument, so we
      # can find associated properties etc.
      def to_spree_attributes(spree_product = nil)
        {
          product_id: spree_product.try(:id),
          sku: @attributes[:sku],
          price: @attributes[:price],
          cost_price: @attributes[:cost_price],
          width: @attributes[:width],
          height: @attributes[:height],
          depth: @attributes[:depth],
          weight: @attributes[:weight],
          is_master: false,
          options: options_array
        }
      end

      def sku
        @attributes[:sku]
      end

      def image_urls
        @attributes[:images].try(:split, ",")
      end

      def stock
        @attributes[:stock]
      end

      def product_sku
        @attributes[:product_sku]
      end

      private

      def options_array
        return [] if @attributes[:options].blank?
        option_strings = @attributes[:options].split(",")
        option_strings.map do |os|
          name, value = os.split(":")
          { name: name, value: value }
        end
      end
    end
  end
end
