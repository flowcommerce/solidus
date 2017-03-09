# added flow specific methods to Spree::Order

require 'digest/sha1'

Spree::Order.class_eval do

  # defines uniqe flow number per order
  # format "solidus-order-hash" -> "s-o-hash"
  def flow_number
    return self[:flow_number] unless self[:flow_number].blank?
    return unless id

    token = ENV.fetch('SECRET_TOKEN')
    number = 's-o-%s' % Digest::SHA1.hexdigest('%d-%s' % [id, token])

    # fast update without callbacks
    update_column :flow_number, number

    number
  end

  def total_price_cache(flow_exp)
    flow_cache['total'][flow_exp.currency]
  rescue
    Flow.price_not_found
  end

end

