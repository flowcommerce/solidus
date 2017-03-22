# represents flow.io order
# for easy intgration we pass current
# - flow experirnce
# - solidus / spree order
# - current customer, presetnt as  @current_spree_user controller instance variable

class FlowError < StandardError
end

class FlowOrder
  attr_reader   :response

  FLOW_CENTER = 'solidus-test'

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
  end

  ###

  def initialize(experience:, spree_order:, customer:)
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
    opts[:organization] = ENV.fetch('FLOW_ORG')
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

    sync_and_update_product_prices!

    @response
  end


  # closes - completes order
  def close_order

  end

  # closes - completes order
  def delete_order

  end

  def sync_and_update_product_prices!
    #puts @response.to_json
    # r @response['items'][0]['local']['prices']
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
    opts_list = @response['deliveries'][0]['options']

    @spree_order.flow_cache ||= {}
    @spree_order.flow_cache['selection'] ||= []

    opts_list.map do |opts|
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

  def add_card(hash_data)
    # {"cvv":"737","expiration_month":8,"expiration_year":2018,"name":"Joe Smith","number":"4111111111111111"}
    # Flow.api :post, '/:organization/cards', BODY: hash_data
    card_form = ::Io::Flow::V0::Models::CardForm.new(hash_data)
    @card = FlowCommerce.instance.cards.post(ENV.fetch('FLOW_ORG'), card_form)
  end

  def finalize!
    # http://docs.solidus.io/Spree/Order.html
    raise FlowError, 'Card is not added' unless @card

    response = Flow.api :post, '/:organization/authorizations', BODY:{"token":@card.token,"order_number":@spree_order.flow_number,"discriminator":"merchant_of_record_authorization_form"}
    if response['result']['status'] == 'authorized'

      # add authorization_id to flow_cache in order
      # maybe it is better to have extra field in spree_orders as we have for flow_number
      @spree_order.update_column :flow_cache, flow_cache.merge('authorization_id': response['id'])

      FlowRoot.logger.info('Flow order "%s" finalized' % @order.token)

      @spree_order.finalize!
    else
      FlowRoot.logger.error(response.to_json)
    end
  end

end

