# added flow specific methods to Spree::Variant
# solidus / spree save all the prices inside Variant object
# we choose to have cache jsonb field named flow_cache that will hold all important
# flow sync data for specific

Spree::Variant.class_eval do

  # used for sync with flow
  def flow_number
    's-variant-%d' % id
  end

  def flow_prices(experience)
    @flow_local = flow_cache['exp'][experience.key]['prices'] rescue nil
  end

  # returns [amount, currency]
  def flow_raw_price(experience)
    @experience = experience
    @flow_local = flow_cache['exp'][experience.key] rescue nil

    # to do: realtime get experience
    return unless @flow_local

    @flow_local['prices'][0] || calculated_local_price
  end

  # we take base rate and calculate prices on the fly
  # if we for some reason do not have cached price
  def calculated_local_price
    price = { 'key': 'localized_item_price' }
    price['amount'] = (@flow_local['rates'].values.first * cost_price * 1.23).round(2)
    price['label']  = '~%.2f %s' % [price['amount'], @experience.currency]
    price
  end

  # rescue price to show unless we product is localized
  def flow_rescue_price(quantity=nil)
    quantity ||= 1
    total_price = quantity * cost_price
    '%.2f %s' % [total_price, cost_currency]
  end

  # returns price tied to local experience
  def flow_local_price(experience)
    raw_price = flow_raw_price(experience)

    return flow_rescue_price unless raw_price

    raw_price['label']
  end

  # gets flow catalog item, and imports it
  # it is intentionally here
  def import_flow_item(item)
    country_id = item.local.experience.key
    rate = item.local.rates[0]

    # be sure to get right exchange rate
    # if we miss rate from api, extract it from first item
    if rate
      ex_rate     = rate.value
      ex_currency = rate.base.downcase
    else
      price       = item.local.prices[0]
      ex_rate     = price.amount / price.base.amount
      ex_currency = price.base.currency
    end

    flow_cache['exp'] ||= {}
    flow_cache['exp'][country_id] = {
      rates: {
        ex_currency => ex_rate
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

