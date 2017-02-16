# helper module to import products to solidus

require 'digest/md5'

# this is made as module, so it can be functional
module Import
  module SolidusDb
    extend self

    # accepts hash with uid (sku), name, desc, price, image and does grunt work to import it
    # to solidus 2.1
    def call(row)
      # name and price is required for import
      return if row[:price].to_s.length == 0
      return if row[:name].to_s.length < 2 || row[:name].to_s.length > 100

      add_product(row)

      true
    end

    # base spree product
    # this method is called for every row, so for master products and variants
    def add_product(row)
      # unique by name. don't create if product exists
      # strangley spree is not povideing any uid in products table.
      # I am using name for now, if that will not work I modify schema and add uid to spree_products
      product = Spree::Product.find_or_initialize_by(name: row[:name])

      # create master product unless found
      unless product.id
        # master sku has M prefix
        product.sku                  = "CUSTOM-M-#{row[:id]}"
        product.price                = row[:price]
        product.description          = row[:description]
        product.available_on         = Time.now
        product.shipping_category_id = 1
        product.tax_category_id      = 1
        product.promotionable        = 1

        # unfortunately this will create master variant as well
        product.save!
      end

      add_image(product, row[:image])

      # if we have defiend size, create it in solidus
      unless row[:size].blank?
        # create size variant type unless exists, and assign it
        size_variant = Import::SolidusDb::create_size_variant(row[:size])

        raise "Can't create size option" unless size_variant.id

        product.option_type_ids = [size_variant.option_type_id]
        product.save!

        # now add propper variant in specified size
        # is_master: false, product_id: product.id
        variant = Spree::Variant.find_or_initialize_by(sku: "CUSTOM-#{row[:id]}")
        variant.product_id      = product.id
        variant.cost_price      = row[:price]
        variant.track_inventory = false
        variant.save!

        # this will link variant to size
        Spree::OptionValuesVariant.find_or_create_by! variant_id: variant.id, option_value_id: size_variant.id
      end

      assign_category product, row[:category]

      product
    end

    # do not add image unless allready exists
    # we check only by variant
    def add_image(product, image_url)
      return if image_url.blank?

      variant = Spree::Variant.find_by(is_master: true, product_id: product.id)
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
    def create_size_variant(size)
      size_type = Spree::OptionType.find_or_initialize_by name: 'size'
      size_type.update! presentation: 'Size' unless size_type.id

      # ensure we have propper variant
      Spree::OptionValue.find_or_create_by! name: size, presentation: size, option_type_id: size_type.id
    end

    # create category and assign product to it
    def assign_category(product, category_path_string)
      path = category_path_string.split(' > ')
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
      Spree::Classification.find_or_create_by! product_id: product.id, taxon_id: taxon.id
    end

  end
end


