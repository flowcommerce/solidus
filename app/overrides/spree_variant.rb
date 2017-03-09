# added flow specific methods to Spree::Variant
# solidus / spree save all the prices inside Variant object
# we choose to have cache jsonb field named flow_cache that will hold all important
# flow sync data for specific

Spree::Variant.class_eval do

  # used for sync with flow
  def flow_number
    id.to_s
  end

  def flow_prices(flow_exp)
    if cache = flow_cache['exp']
      if data = cache[flow_exp.key]
        data['prices'] || []
      end
    end
  end

  # returns [amount, currency]
  def flow_raw_price(flow_exp)
    local = flow_cache['exp'][flow_exp.key] if flow_cache['exp']

    # to do: realtime get experience
    return unless local

    local['prices'][0] || Flow.price_not_found
  end

  # rescue price to show unless we product is localized
  def flow_rescue_price(quantity=nil)
    Flow.price_not_found
  end

  # returns price tied to local experience
  def flow_local_price(flow_exp)
    raw_price = flow_raw_price(flow_exp)

    return flow_rescue_price unless raw_price

    raw_price['label']
  end

  # gets flow catalog item, and imports it
  # it is intentionally here
  def import_flow_item(item)
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
end

