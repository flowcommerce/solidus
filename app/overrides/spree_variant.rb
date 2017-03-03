# added flow specific methods to Spree::Variant
# solidus / spree save all the prices inside Variant object
# we choose to have cache jsonb field named flow_cache that will hold all important
# flow sync data for specific

Spree::Variant.class_eval do

  # used for sync with flow
  def flow_number
    's-variant-%d' % id
  end

  # returns [amount, currency]
  def flow_raw_price(experience)
    flow_cache ||= {}
  end

  # returns price tied to local experience
  def flow_local_price(experience)
    local = flow_cache['exp'].values.select{ |el| el['key'] == experience['key'] }[0]

    # to do: realtime get experience
    return 'n/a' unless local

    local['prices'][0]['label']
  end

  # gets flow catalog item, and imports it
  def import_flow_item(item)
    country_id = item.local.experience.id
    rate = item.local.rates[0]

    flow_cache['exp'] ||= {}
    flow_cache['exp'][country_id] = {
      key: item.local.experience.key,
      rates: {
        rate.base.downcase => rate.value
      }
    }

    flow_cache['exp'][country_id]['prices'] = item.local.prices.map do |price|
      price = price.to_hash
      price.delete :base
      price.delete :currency
      [:includes, :adjustment].each { |el| price.delete(el) unless price[el] }
      price
    end

    update_column :flow_cache, flow_cache.dup
  end
end

