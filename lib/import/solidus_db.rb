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

      product = add_product(row)
      add_image(product, row)

      true
    end

    # base spree product
    def add_product(row)
      # unique by name. don't create if product exists
      product = Spree::Product.find_or_initialize_by(name: row[:name])
      product.sku                  = "GILT-#{row[:uid]}"
      product.price                = row[:price]
      product.cost_price           = row[:price]
      product.description          = row[:description]
      product.slug                 = row[:name].to_slug
      product.available_on         = Time.now
      product.shipping_category_id = 1
      product.tax_category_id      = 1
      product.promotionable        = 1
      product.save!

      # info: variants are automaticly created when products are created

      product
    end

    # do not add image unless allready exists
    # we check only by variant
    def add_image(product, row)
      return unless row[:image]

      variant = Spree::Variant.find_by(is_master: true, product_id: product.id)
      raise 'Product variant not found' unless variant

      image = Spree::Image.find_or_initialize_by viewable_id: variant.id
      return if image.id

      local_image = get_local_image row[:image]
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

  end
end


