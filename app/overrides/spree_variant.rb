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

  # used for sync with flow
  def flow_number
    id.to_s
  end

  def flow_prices(flow_exp)
    if cache = flow_cache['exp']
      if data = cache[flow_exp.key]
        return data['prices'] || []
      end
    end
    []
  end

  # rescue price to show unless we product is localized
  def flow_rescue_price(flow_exp)
    # we can just return 'n/a' and skip auto import part

    flow_item = flow_get_item(flow_exp)

    # if there is no item, we created item in catalog in flow but returned nil
    return Flow.price_not_found unless flow_item

    # we have flow item, import it!
    flow_import_item(flow_item)

    # try to get price one more time
    price = flow_prices(flow_exp).first
    return Flow.price_not_found unless price
    price['label']
  end

  # returns price tied to local experience
  def flow_local_price(flow_exp)
    price = flow_prices(flow_exp).first
    return flow_rescue_price(flow_exp) unless price
    price['label']
  end

  # creates object for flow api
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
      price.delete :base
      price.delete :currency
      [:includes, :adjustment].each { |el| price.delete(el) unless price[el] }
      price
    end

    update_column :flow_cache, flow_cache.dup
  end

  # gets item by number or just pass spree variant or spree product
  def flow_get_item(flow_exp)
    FlowCommerce.instance.experiences.get_items_by_number FlowExperience.organization, flow_number, country: flow_exp.key
  rescue Io::Flow::V0::HttpClient::ServerError
    FlowCommerce.instance.items.put_by_number FlowExperience.organization, flow_number, flow_api_item
    nil
  end
end

