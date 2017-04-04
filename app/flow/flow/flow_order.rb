# represents flow.io order
# for easy intgration we pass current
# - flow experirnce
# - solidus / spree order
# - current customer, presetnt as  @current_spree_user controller instance variable

class FlowError < StandardError
end

class FlowOrder
  attr_reader   :response

  FLOW_CENTER = 'default'

  class << self

    # helper method to send complete order from spreee and make auto sync
    def sync_from_spree_order(experience:, order:, customer: nil)
      flow_order = new experience: experience, spree_order: order, customer: customer

      order.line_items.each do |line_item|
        flow_order.add_item line_item
      end

      flow_order.synchronize
      flow_order
    end

    # adds cc and gets cc token
    def add_card(cc_hash:, credit_card:)
      raise ArgumentError, 'Credit card card class is not %s' % Spree::CreditCard unless credit_card.class == Spree::CreditCard

      # {"cvv":"737","expiration_month":8,"expiration_year":2018,"name":"Joe Smith","number":"4111111111111111"}
      card_form = ::Io::Flow::V0::Models::CardForm.new(cc_hash)
      @card = FlowCommerce.instance.cards.post(ENV.fetch('FLOW_ORGANIZATION'), card_form)

      @card
    end

  end

  ###

  def initialize(spree_order:, experience: nil, customer: nil)
    if experience
      # update order experience unless defined
      # we need this for orders, to make accurate order in defined experience
      if spree_order.flow_cache['experience_key'] != experience.key
        spree_order.update_column :flow_cache, spree_order.flow_cache.merge(experience_key: experience.key)
      end
    else
      experience = flow_cache['experience_key']

      raise(ArgumentError, 'Experience not defined and not found in flow cache.') unless experience
    end

    @experience  = experience
    @spree_order = spree_order
    @customer    = customer
    @items       = []
  end

  def set_sku(sku)
    @sku = sku
  end

  def add_item(line_item)
    variant   = line_item.variant

    # create flow order line item
    item = {
      center: FLOW_CENTER,
      number: variant.id.to_s,
      quantity: line_item.quantity,
      price: {
        amount:   variant.cost_price,
        currency: variant.cost_currency
      }
    }

    @items.push item
  end

  # synchronize with flow
  def synchronize
    flow_number = @spree_order.flow_number

    opts = {}
    opts[:organization] = ENV.fetch('FLOW_ORGANIZATION')
    opts[:experience] = @experience.key
    opts[:BODY] = {
      items:  @items,
      number: flow_number
    }

    # if customer is defined, add customer info
    # it is possible to have order in solidus without customer info (new guest session)
    if @customer
      opts[:customer] = {
        email: @customer.email,
        number: @customer.flow_number,
      }

      if (address = @customer.ship_address)
        streets = []
        streets.push address.address1 unless address.address1.blank?
        streets.push address.address2 unless address.address2.blank?

        opts[:destination] = {
          streets:  streets,
          city:     address.city,
          province: address.state_name,
          postal:   address.zipcode,
          country: (address.country.name rescue ''),
          contact: {
            number: @customer.flow_number,
            email:  @customer.email,
            name:   '%s %s' % [address.firstname, address.lastname],
            phone:  address.phone
          }
        }

        [:name, :phone].each do |field|
          opts[:customer][field] = address[field] unless address[field].blank?
        end
      end
    end

    # add selection (delivery options) from flow_cache
    @spree_order.flow_cache['selection'] ||= []
    @spree_order.flow_cache['selection'].delete('placeholder')
    opts[:selection] = @spree_order.flow_cache['selection']

    # body = opts.delete(:BODY)
    # body[:items].map! { |item| ::Io::Flow::V0::Models::LineItemForm.new(item) }
    # order_put_form = ::Io::Flow::V0::Models::OrderPutForm.new(body)
    # FlowCommerce.instance.orders.put_by_number(ENV.fetch('FLOW_ORGANIZATION'), flow_number, order_put_form, opts)
    # return

    @response = FlowRoot.api(:put, '/:organization/orders/%s' % flow_number, opts)

    # set cache for total order ammount
    # written in flow_cache field inside spree_orders table
    if (total = @response['total'])
      @spree_order.flow_cache ||= {}
      @spree_order.flow_cache['total'] ||= {}
      if @spree_order.flow_cache['total'][@experience.key] != total['label']
        @spree_order.flow_cache['total'][@experience.key] = total['label']
        @spree_order.update_column :flow_cache, @spree_order.flow_cache
      end
    end

    @response
  end

  def total_price
    @response['total']['label'] rescue 'n/a'
  end

  # accepts line item
  def line_item_price(line_item, total=false)
    id = line_item.variant.id.to_s

    @response['lines'] ||= []
    item = @response['lines'].select{ |el| el['item_number'] == id }.first
    return FlowRoot.price_not_found unless item

    total ? item['total']['label'] : item['price']['label']
  end

  def deliveries
    delivery_list = @response['deliveries'][0]['options']

    @spree_order.flow_cache ||= {}
    @spree_order.flow_cache['selection'] ||= []

    delivery_list = delivery_list.map do |opts|
      name         = opts['tier']['name']
      name        += ' (%s)' % opts['tier']['strategy'] if opts['tier']['strategy']
      selection_id = opts['id']

      {
        id:    selection_id,
        price: { label: opts['price']['label'] },
        active: @spree_order.flow_cache['selection'].include?(selection_id),
        name: name
      }
    end.to_a

    # make first one active unless we have active element
    delivery_list.first[:active] = true unless delivery_list.select{ |el| el[:active] }.first

    delivery_list
  end

  def delivery
    deliveries.select{ |o| o[:active] }.first
  end

  def error?
    @response['code'] == 'generic_error'
  end

  def error
    @response['messages'].join(', ')
  end

end

