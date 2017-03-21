# added flow specific methods to Spree::Order

require 'digest/sha1'

Spree::Order.class_eval do

  before_save do
    # ap self
  end

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

end

