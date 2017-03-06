# general flow helper

module FlowHelper

  # live hot fix product or variant
  # not used for now
  # def flow_fix_price(product)
  #   return unless product.respond_to?(:sku) && product.respond_to?(:cost_price) && product.respond_to?(:cost_currency)

  #   fcc = FlowCatalogCache.load_by_country_and_sku @flow_exp, product.sku

  #   product.cost_price    = fcc[:amount]
  #   product.cost_currency = fcc[:currency]
  #   product
  # end

  # @param product [Spree::Product]
  #
  # shows localized price of the product
  # def flow_price(product)
  #   # we want to keep all flow logic in flow classes
  #   Flow.render_price_from_flow(@flow_exp, product) || '$ %s' % product.price
  # end

  # get flow item from line item and shows localized price
  # used in app/views/spree/orders/_line_item.html.erb
  # old: line_item.single_money.to_html
  def flow_line_item_price(line_item, quantity=nil)
    # will localize only once unless localized
    return 999

    flow_localize_cart

    quantity = 1 if quantity.to_i < 1

    sku = line_item.variant.sku.downcase
    flow_product = FlowCatalogCache.load_by_country_and_sku(@flow_exp, sku)

    # this should allways be true coz flow_localize_cart sould set it
    if flow_api_item = @localized_order[sku]

      # if price from flow api is not the same one in cache, update cache
      if flow_api_item[:price] != flow_product[:amount]
        FlowCatalogCache.update_price_by_country_and_sku country: @flow_exp, sku: sku, price: flow_api_item[:price]
        flow_product['amount'] = flow_api_item[:price]
      end
    end

    total = flow_product[:amount] * quantity

    Flow.format_price(total, @flow_exp)
  end

  # localizes order items
  # we will get order items from flow api to show products in cart, insted of
  # spree default line items
  def flow_localize_cart
    return if @localized_order

    @localized_order = {}

    items = []
    local_cache = {}

    @order.line_items.each do |line_item|
      variant = line_item.variant

      local_price = variant.flow_raw_price(@flow_exp)

      # for flow api
      items.push({
        number: variant.flow_number,
        center: 'solidus-test', # this should come from experience
        quantity: line_item.quantity,
        price: { amount: local_price['amount'].to_f, currency: @flow_exp.currency }
      })
    end

    opts = {}
    opts[:organization] = Flow.organization
    opts[:experience] = @flow_exp[:key]
    opts[:BODY] = { items: items }

    # croatia
    # opts[:ip] = '188.129.64.124'

    # mock canada IP
    opts[:ip] = '192.206.151.131'

    # flow_data = Flow.api :post, '/:organization/order-estimates', opts

    # flow_data['items'].each do |item|
    #   sku   = item['number'].downcase
    #   price = item['local']['prices'].first['amount']

    #   @localized_order[sku] = {
    #     name:     item['name'],
    #     quantity: item['quantity'],
    #     price:    price,
    #     currency: item['local']['prices'].first['currency']
    #   }

    # end
  end

end
