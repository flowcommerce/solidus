# added flow specific methods to Spree::Order
# http://docs.solidus.io/Spree/Order.html

require 'digest/sha1'

Spree::Order.class_eval do

  # we now use Solidus number as Flow number, but I will this here for now
  def flow_number
    return self[:flow_number] unless self[:flow_number].blank?
    return unless id
    number
  end

  def flow_order
    return nil unless flow_data['order']
    @_flow_hashie ||= Hashie::Mash.new(flow_data['order'])
  end

  # accepts line item, usually called from views
  def flow_line_item_price line_item, total=false
    unless flow_order
      Flow.format_default_price(line_item.price * (total ? line_item.quantity : 1))
    else
      id = line_item.variant.id.to_s

      lines = flow_order.lines || []
      item  = lines.select{ |el| el['item_number'] == id }.first

      return Flow.price_not_found unless item

      total ? item['total']['label'] : item['price']['label']
    end
  end

  # prepares array of prices that can be easily renderd in templates
  def flow_cart_breakdown
    prices = []

    price_model = Struct.new(:name, :label)

    if flow_order
      # duty, vat, ...
      unless flow_order.prices
        message = Flow::Error.format_message flow_order
        raise Flow::Error.new(message)
      end

      flow_order.prices.each do |price|
        prices.push price_model.new(price['key'].to_s.capitalize , price['label'])
      end
    else
      price_elements = [:item_total, :adjustment_total, :included_tax_total, :additional_tax_total, :tax_total, :shipment_total, :promo_total]
      price_elements.each do |el|
        price = send(el)
        if price > 0
          label = Flow.format_default_price price
          prices.push price_model.new(el.to_s.humanize.capitalize, label)
        end
      end
    end

    # total
    prices.push price_model.new(Spree.t(:total), flow_total)

    prices
  end

  # shows localized total, if possible. if not, fall back to Solidus default
  def flow_total flow_experience_key=nil
    # r
    if flow_order && flow_order.total
      if flow_experience_key && flow_order.experience[:key] != flow_experience_key
        # response = Flow::Order.new(order: self).synchronize!
        # r response
      end

      price = flow_order.total.label
    end
    price || Flow.format_default_price(total)
  end

  # returns localized price part if in flow, or solidus one if not
  def flow_total_part
    model = Struct.new(:amount, :currency)

    if flow_order
      model.new(flow_order.total.amount, flow_order.total.currency)
    else
      model.new(total, currency)
    end
  end

  def flow_experience
    model = Struct.new(:key)
    model.new flow_order.experience.key
  rescue
    model.new ENV.fetch('FLOW_BASE_COUNTRY')
  end

  # clear invalid zero amount payments. Solidsus bug?
  def clear_zero_amount_payments!
    # class attribute that can be set to true
    return unless Flow::Order.clear_zero_amount_payments

    payments.where(amount:0, state: ['invalid', 'processing', 'pending']).map(&:destroy)
  end

  def flow_order_authorized?
    flow_data && flow_data['authorization'] ? true : false
  end

  # completes order and sets all states to finalized and complete
  # used when we have confirmed capture from Flow API or PayPal
  def flow_finalize!
    finalize! unless state == 'complete'
    update_column :payment_state, 'paid' if payment_state != 'paid'
    update_column :state, 'complete'     if state != 'complete'
  end

end

