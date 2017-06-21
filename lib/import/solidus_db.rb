# helper module to import products to solidus

require 'digest/md5'

# this is made as module, so it can be functional
module Import
  class SolidusDb
    class << self
      def call row
        new row
      end
    end

    # accepts hash with uid (sku), name, desc, price, image and does grunt work to import it
    # to solidus 2.1
    def initialize row
      @row = row
      # name and price is required for import
      return if @row[:price].to_s.length == 0
      return if @row[:name].to_s.length < 2 || @row[:name].to_s.length > 100

      add_product

      true
    end

    # base spree product
    # this method is called for every row, so for master products and variants
    def add_product
      # unique by name. don't create if product exists
      # strangley spree is not povideing any uid in products table.
      # I am using name for now, if that will not work I modify schema and add uid to spree_products
      @product = Spree::Product.find_or_initialize_by(name: @row[:name])

      # master sku has M prefix
      @product.sku                  = "m-#{@row[:id]}"
      @product.price                = @row[:price]
      @product.description          = @row[:description]
      @product.available_on         = Time.now
      @product.shipping_category_id = 1
      @product.tax_category_id      = 1
      @product.promotionable        = 1
      @product.save! # this will create master variant as well

      # now add variant
      # is_master: false, product_id: @product.id
      @variant = Spree::Variant.find_or_initialize_by sku: @row[:id]
      @variant.product_id      = @product.id
      @variant.cost_price      = @row[:price]
      @variant.track_inventory = false
      @variant.save!

      add_image
      add_variants

      # @product.option_type_ids = option_type_ids
      # @product.save!

      assign_category
    end

    def add_variants
      # size variant
      size = @row[:size]
      size = nil if size == 'No size'
      create_variant('size', size) if size

      # size variant
      if color = @row[:color]
        color = color.split(' ').map(&:capitalize).join(' ')
        create_variant('color', color)
      end

      # sex variant
      # can be added, but bette not becuase we have only two options
      # create_variant('sex', @row[:sex]) if @row[:sex]
    end

    # do not add image unless allready exists
    # we check only by variant
    def add_image
      image_url = @row[:image]
      return if image_url.blank?

      variant = Spree::Variant.find_by(is_master: true, product_id: @product.id)
      raise 'Product variant not found' unless variant

      image = Spree::Image.find_or_initialize_by viewable_id: variant.id
      return if image.id

      local_image = get_local_image image_url
      image.attachment    = File.open(local_image, 'r')
      image.viewable_type = 'Spree::Variant'
      image.save
    end

    # returns local image or dl
    def get_local_image(uri)
      # local?
      return uri unless uri[0,4] == 'http'

      ext = uri.split('.').last

      img_folder = './tmp/dl_img'
      Dir.mkdir(img_folder) unless Dir.exist?(img_folder)

      local_file = "#{img_folder}/#{Digest::MD5.hexdigest(uri)}.#{ext}"

      # wget is reliable downloader
      `wget -O #{local_file} #{uri}` unless File.exists?(local_file)

      local_file
    end

    # we need tables prepared for possible proucts sizes
    # this will be base for our variants
    def create_variant(type, value)
      value_type = Spree::OptionType.find_or_initialize_by name: type
      value_type.update! presentation: type.capitalize unless value_type.id

      # ensure we have propper variant
      option_value = Spree::OptionValue.find_or_create_by! name: value, presentation: value, option_type_id: value_type.id

      # this will link variant to size
      Spree::OptionValuesVariant.find_or_create_by! variant_id: @variant.id, option_value_id: option_value.id
    end

    # create category and assign product to it
    def assign_category
      path = @row[:category]
      root = path.shift

      # this just needs to be set, for apparently no valid reason
      # I think think model is complely useless
      taxonomy = Spree::Taxonomy.find_or_create_by!(name:root)

      # here is real root of taxonomy tree
      taxon = Spree::Taxon.find_or_create_by!(parent_id: nil, taxonomy_id: taxonomy.id, name: root)

      # now check for existance of 2 parent elements, 3 and n+ is ignorred
      taxon = Spree::Taxon.find_or_create_by!(parent_id: taxon.id, taxonomy_id: taxonomy.id, name: path[0]) if path[0]
      taxon = Spree::Taxon.find_or_create_by!(parent_id: taxon.id, taxonomy_id: taxonomy.id, name: path[1]) if path[1]

      # it is weird why this model is named Spree::Classification instead of Spree::ProductsTaxon
      # it maps to "spree_products_taxons" table
      Spree::Classification.find_or_create_by! product_id: @product.id, taxon_id: taxon.id
    end

  end
end


