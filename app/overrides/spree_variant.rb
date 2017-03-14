# added flow specific methods to Spree::Variant
# solidus / spree save all the prices inside Variant object
# we choose to have cache jsonb field named flow_cache that will hold all important
# flow sync data for specific

Spree::Variant.class_eval do

  # clears flow cache from all records
  def self.flow_truncate
    all_records = all
    all_records.each { |o| o.update_column :flow_cache, {} }
    puts 'Truncated %d records' % all_records.length
  end

  def flow_prices(flow_exp)
    if cache = flow_cache['exp']
      if data = cache[flow_exp.key]
        return data['prices'] || []
      end
    end
    []
  end

  # returns price tied to local experience
  def flow_local_price(flow_exp)
    # TODO: Show all prices, not just first
    if price = flow_prices(flow_exp).first
      price['label']
    else
      # TODO: Fallback to USD Price here
      nil
    end
  end

  # creates object for flow api
  # TODO: Remove and use the one in rakefile
  def flow_api_item
    image_base = 'http://cdn.color-mont.com'

    Io::Flow::V0::Models::ItemForm.new(
      number:      flow_number,
      locale:      'en_US',
      language:    'en',
      name:        product.name,
      description: product.description,
      currency:    cost_currency,
      price:       cost_price.to_f,
      images: [
        { url: image_base + product.display_image.attachment(:large), tags: ['main'] },
        { url: image_base + product.images.first.attachment.url(:product), tags: ['thumbnail'] }
      ]
    )
  end

  # gets flow catalog item, and imports it
  # it is intentionally here
  def flow_import_item(item)
    experience_key = item.local.experience.key
    flow_cache['exp'] ||= {}
    flow_cache['exp'][experience_key] = {}
    flow_cache['exp'][experience_key]['prices'] = item.local.prices.map do |price|
      price = price.to_hash
      [:includes, :adjustment].each { |el| price.delete(el) unless price[el] }
      price
    end

    update_column :flow_cache, flow_cache.dup
  end

end

