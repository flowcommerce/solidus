# represents flow.io order
# for easy intgration we pass current
# - flow experirnce
# - solidus / spree order
# - current customer, presetnt as  @current_spree_user controller instance variable
#
# example:
#  flow_order = Flow::Order.new    # init flow-order object
#    order: Spree::Order.last,
#    experience: Flow::Experience.default,
#    customer: Spree::User.last
#  fo.build_flow_request           # builds json body to be posted to flow api
#  fo.synchronize!                 # sends order to flow

class Flow::Order
  FLOW_CENTER = 'default' unless defined?(::Flow::Order::FLOW_CENTER)

  attr_reader     :response
  attr_reader     :order
  attr_reader     :customer
  attr_reader     :body

  def initialize order:, experience: nil, customer: nil
    unless experience
      if order.flow_order
        experience = Flow::Experience.get(order.flow_order['experience']['key'])
      else
        raise(ArgumentError, 'Experience not defined and not found in flow data')
      end
    end

    @experience = experience
    @order      = order
    @customer   = customer
    @items      = []
  end

  # helper method to send complete order from spreee to flow
  def synchronize!
    sync_body!
    check_state!
    write_response_in_cache
    @response
  end

  def error?
    @response && @response['code'] && @response['messages']
  end

  def error
    @response['messages'].join(', ')
  end

  def delivery
    deliveries.select{ |el| el[:active] }.first
  end

  # delivery methods are defined in flow console
  def deliveries
    # if we have erorr with an order, but still using this method
    return [] unless @order.flow_order

    @order.flow_data ||= {}

    delivery_list = @order.flow_order['deliveries'][0]['options']
    delivery_list = delivery_list.map do |opts|
      name         = opts['tier']['name']
      name        += ' (%s)' % opts['tier']['strategy'] if opts['tier']['strategy']
      selection_id = opts['id']

      {
        id:    selection_id,
        price: { label: opts['price']['label'] },
        active: @order.flow_order['selections'].include?(selection_id),
        name: name
      }
    end.to_a

    # make first one active unless we have active element
    delivery_list.first[:active] = true unless delivery_list.select{ |el| el[:active] }.first

    delivery_list
  end

  def total_price
    @order.flow_total
  end

  private

  # if customer is defined, add customer info
  # it is possible to have order in solidus without customer info (new guest session)
  def add_customer opts
    return unless @customer

    if (address = @customer.ship_address)
      opts[:customer] = {
        name:   {
          first: address.firstname,
          last: address.lastname
        },
        email:  @customer.email,
        number: @customer.flow_number,
        phone:  address.phone
      }

      streets = []
      streets.push address.address1 unless address.address1.blank?
      streets.push address.address2 unless address.address2.blank?

      opts[:destination] = {
        streets:  streets,
        city:     address.city,
        province: address.state_name,
        postal:   address.zipcode,
        country: (address.country.iso3 rescue 'USA'),
        contact: opts[:customer]
      }

      opts[:destination].delete_if { |k,v| v.nil? }
    end

    opts
  end

  # builds object that can be sent to api.flow.io to sync order data
  def build_flow_request
    @order.line_items.each do |line_item|
      add_item line_item
    end

    flow_number = @order.flow_number

    opts = {}
    opts[:organization] = Flow.organization
    opts[:experience]   = @experience.key
    opts[:expand]       = 'experience'

    body = {}
    body = {
      items:  @items,
      number: flow_number
    }

    add_customer body if @customer

    # if defined, add selection (delivery options) and delivered_duty from flow_data
    body[:selections]     = [@order.flow_data['selection']]    if @order.flow_data['selection']
    body[:delivered_duty] = @order.flow_data['delivered_duty'] if @order.flow_data['delivered_duty']

    # discount on full order is applied
    if @order.adjustment_total != 0
      body[:discount] = {
        amount: @order.adjustment_total,
        currency: @order.currency
      }
    end

    # calculate digest body and cache it
    digest = Digest::SHA1.hexdigest(opts.to_json + body.to_json)

    [opts, body, digest]
  end

  def sync_body!
    opts, @body, digest = build_flow_request

    use_get = @order.state == 'complete' || @order.flow_data['digest'] == digest
    use_get = false unless @order.flow_data['order']

    if use_get
      # if digest @body matches, use get to build request
      @response = Flow.api :get, '/:organization/orders/%s' % @body[:number], expand: 'experience'
    else
      @order.flow_data['digest'] = digest

      # replace when fixed integer error
      # @body[:items].map! { |item| ::Io::Flow::V0::Models::LineItemForm.new(item) }
      # opts[:experience] = @experience.key
      # order_put_form = ::Io::Flow::V0::Models::OrderPutForm.new(@body)
      # r FlowCommerce.instance.orders.put_by_number(Flow.organization, @order.flow_number, order_put_form, opts)

      @response = Flow.api :put, '/:organization/orders/%s' % @body[:number], opts, @body
    end
  end

  def check_state!
    @order.flow_finalize! if @order.flow_order_authorized? && @order.state != 'complete'
  end

  def add_item line_item
    variant   = line_item.variant

    price_root = variant.flow_data['exp'][@experience.key]['prices'][0] rescue {}

    # create flow order line item
    item = {
      center: FLOW_CENTER,
      number: variant.id.to_s,
      quantity: line_item.quantity,
      price: {
        amount:   price_root['amount']   || variant.cost_price,
        currency: price_root['currency'] || variant.cost_currency
      }
    }

    @items.push item
  end

  # set cache for total order ammount
  # written in flow_data field inside spree_orders table
  def write_response_in_cache
    response_total = @response.dig('total', 'label')

    if @response && response_total && response_total != @order.flow_data.dig('order', 'total', 'label')
      @order.flow_data['order'] = @response.to_hash
      @order.save
    end
  end

end

