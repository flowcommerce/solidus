# represents flow order

class FlowOrder

  FLOW_CENTER = 'solidus-test'

  class << self

    # helper method to send complete order from spreee and make auto sync
    def init_from_spree_order(experience:, order:, address:)
      flow_order = new experience: experience, order: order, address: address

      order.line_items.each { |line_item| flow_order.add_item line_item }
    end

  end

  ###

  def initialize(experience:, order:, address:)
    @experience = experience
    @order = order
    @order = address
    @items = []
  end

  def set_sku(sku)
    @sku = sku
  end

  def set_client(client)
    @client = client
  end

  def add_item(object)

    item = if object.is_a?(Hash)
      object
    else
      fcc = FlowCatalogCache.load_by_country_and_sku @experience.country, object.sku

      {
        center: FLOW_CENTER,
        number: 'spree-%s' % object.variant_id,
        quantity: object.quantity,
        price: {
          amount:   fcc[:amount].to_f,
          currency: fcc[:currency]
        }
      }
    end

    @items.push item
  end

  # synchronize with flow
  def synchronize
    #     "code" => "generic_error",
    # "messages" => [ [0] "An order with the specified number already exists"]
  end


  # closes - completes order
  def close_order

  end

  # closes - completes order
  def delete_order

  end
end


### example

# variants = []
# variants.push Spree::Variant.order('random()').first
# variants.push Spree::Variant.order('random()').first

# items = variants.inject([]) { |list, variant|
#   list.push({
#     number: variant.sku,
#     center: 'solidus-test',
#     quantity: 3,
#     price: { amount: variant.price.to_f, currency: 'CAD' }
#   })

#   list
# }


# opts = {}
# opts[:organization] = org
# opts[:experience] = 'canada'
# opts[:BODY] = {
#   items:  items,
#   number: 'spree-test'
# }

# # # croatia
# # # opts[:ip] = '188.129.64.124'

# # canada
# opts[:ip] = '192.206.151.131'

# # ap Flow.api :post, '/:organization/orders', opts

# ap Flow.api :put, '/:organization/orders/spree-test', opts

