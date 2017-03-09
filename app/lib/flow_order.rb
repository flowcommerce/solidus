# represents flow.io order
# for easy intgration we pass current
# - flow experirnce
# - solidus / spree order
# - current customer, presetnt as  @current_spree_user controller instance variable

class FlowOrder
  attr_reader :response

  FLOW_CENTER = 'solidus-test'

  class << self

    # helper method to send complete order from spreee and make auto sync
    def sync_from_spree_order(experience:, order:, customer: nil)
      flow_order = new experience: experience, order: order, customer: customer

      order.line_items.each do |line_item|
        flow_order.add_item line_item
      end

      flow_order.synchronize
      flow_order
    end
  end

  ###

  def initialize(experience:, order:, customer:)
    @experience = experience
    @order = order
    @customer = customer
    @items = []
  end

  def set_sku(sku)
    @sku = sku
  end

  def set_client(client)
    @client = client
  end

  def add_item(line_item)
    variant   = line_item.variant

    # create flow order line item
    item = {
      center: FLOW_CENTER,
      number: variant.flow_number,
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
    flow_number = @order.flow_number

    opts = {}
    opts[:organization] = ENV.fetch('FLOW_ORG')
    opts[:experience] = @experience[:key]
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

    @response = Flow.api(:put, '/:organization/orders/%s' % flow_number, opts)

    # set cache for total order ammount
    # written in flow_cache field inside spree_orders table
    if (total = @response['total'])
      @order.flow_cache ||= {}
      @order.flow_cache['total'] ||= {}
      if @order.flow_cache['total'][total['currency']] != total['label']
        @order.flow_cache['total'][total['currency']] = total['label']
        @order.update_column :flow_cache, @order.flow_cache
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
    @response['total']['label']
  end

  # accepts line item
  def line_item_price(line_item, total=false)
    id = line_item.variant.id.to_s

    item = @response['lines'].select{ |item| item['item_number'] == id }.first
    return Flow.price_not_found unless item

    total ? item['total']['label'] : item['price']['label']
  end
end

# Flow.api :post, '/:organization/cards', BODY:{"name": "Joe Smith","number":"4111111111111111","expiration_month":8,"expiration_year":2018,"cvv":"737"}
# Flow.api :post, '/sessions/organizations/:organization', BODY:{ discriminator: 'organization_session_form', experience: 'canada' }
# Flow.api :post, '/:organization/authorizations', BODY:{"token":"F96Jxcp4YQwIiBOpEPhf7qCcOvqfiM05ZZpM9ELTVa48DDhldDpkglkjFVsXMPon","discriminator":"merchant_of_record_authorization_form","order_number":'o123'}