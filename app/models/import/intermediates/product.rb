module Import
  module Intermediates
    # Intermediate product for importing/exporting
    class Product
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
          name: @attributes[:name],
          sku: @attributes[:sku],
          description: @attributes[:description],
          price: @attributes[:price],
          cost_price: @attributes[:cost_price],
          shipping_category: spree_shipping_category,
          tax_category: spree_tax_category,
          available_on: available_on_date,
          width: @attributes[:width],
          height: @attributes[:height],
          depth: @attributes[:depth],
          weight: @attributes[:weight],
          meta_title: @attributes[:meta_title],
          meta_description: @attributes[:meta_description],
          meta_keywords: @attributes[:meta_keywords],
          product_properties_attributes: spree_product_properties_attributes(
            spree_product
          )
        }
      end

      def image_urls
        @attributes[:images].try(:split, ",")
      end

      # TODO: Use attr for these simple methods
      def name
        @attributes[:name]
      end

      def sku
        @attributes[:sku]
      end

      def stock
        @attributes[:stock]
      end

      def taxon_strings
        @attributes[:taxons].try(:split, ",")
      end

      private

      def spree_shipping_category
        shipping_category = if @attributes[:shipping_category_id].present?
          Spree::ShippingCategory.find(@attributes[:shipping_category_id])
        elsif @attributes[:shipping_category].present?
          Spree::ShippingCategory.find_by(name: @attributes[:shipping_category])
        end
        shipping_category || default_shipping_category
      end

      def default_shipping_category
        Spree::ShippingCategory.find_or_create_by(name: "Default")
      end

      def spree_tax_category
        tax_category = if @attributes[:tax_category_id].present?
          Spree::TaxCategory.find(@attributes[:tax_category_id])
        elsif @attributes[:tax_category].present?
          Spree::TaxCategory.find_by(name: @attributes[:tax_category])
        end
        tax_category || default_tax_category
      end

      def default_tax_category
        Spree::TaxCategory.find_or_create_by(name: "Default")
      end

      def available_on_date
        return nil if @attributes[:available_on].blank?
        Date.parse @attributes[:available_on]
      end

      # Assumes @attributes[:properties] has format "material:cotton,neck:vee"
      def spree_product_properties_attributes(spree_product = nil)
        return [] if @attributes[:properties].blank?
        properties = @attributes[:properties].split(",")
        properties.map do |property|
          name, value = property.split(":")
          spree_product_property_attributes(name, value, spree_product)
        end
      end

      def spree_product_property_attributes(name, value, spree_product = nil)
        {
          id: spree_product_property_id(name, spree_product),
          property_name: name,
          value: value
        }
      end

      def spree_product_property_id(name, spree_product = nil)
        return nil unless spree_product.present? # spree_product may not be created yet
        spree_product.product_properties.find_by(
          property: Spree::Property.find_by(name: name)
        ).try(:id)
      end
    end
  end
end
