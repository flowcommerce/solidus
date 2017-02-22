module FlowHelper

  # live hot fix product or variant
  # not used for now
  def flow_fix_price(product)
    return unless product.respond_to?(:sku) && product.respond_to?(:cost_price) && product.respond_to?(:cost_currency)

    fcc = FlowCatalogCache.load_by_country_and_sku @flow_exp, product.sku

    product.cost_price    = fcc[:amount]
    product.cost_currency = fcc[:currency]
    product
  end

  # @param product [Spree::Product]
  #
  # shows localized price of the product
  def flow_price(product)
    # we want to keep all flow logic in flow classes
    Flow.render_price_from_flow(@flow_exp, product) || '$ %' % product.price
  end

  # @return [String] - cart total - ex: 88.99 CAD
  def flow_cart_total
    return @cart_total if @cart_total

    # format price
    # go trough each element in line item and caluclutate exact price
    # !!! add fallback code if product by sku not found
    amount = simple_current_order.line_items.inject(0) do |total, line_item|
      sku = line_item.variant.sku
      flow_product = FlowCatalogCache.load_by_country_and_sku(@flow_exp, sku)
      flow_product[:amount] * line_item.quantity + total
    end

    @cart_total = Flow.format_price(amount, @flow_exp)
  end

  # this renders link to cart with total cart price
  def flow_link_to_cart(text=nil)
    text = text ? h(text) : Spree.t(:cart)

    if simple_current_order.nil? || simple_current_order.item_count.zero?
      text = '%s: (%s)' % [text, Spree.t(:empty)]
      css_class = :empty
    else
      text = '%s: (%s) <span class="amount">%s</span>' % [text, simple_current_order.item_count, flow_cart_total]
      css_class = :full
    end

    link_to text.html_safe, spree.cart_path, class: 'cart-info %s' % css_class
  end

  # get flow item from line item and shows localized price
  # used in app/views/spree/orders/_line_item.html.erb
  # old: line_item.single_money.to_html
  def flow_line_item_price(line_item, quantity=nil)
    # will localize only once unless localized
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

    @order.line_items.each do |product|
      sku     = product.variant.sku

      # for flow api
      items.push({
        number: sku,
        center: 'solidus-test',
        quantity: product.quantity,
        price: { amount: product.price.to_f, currency: 'USD' }
      })
    end

    opts = {}
    opts[:organization] = Flow.organization
    opts[:experience] = 'canada'
    opts[:BODY] = { items: items }

    # croatia
    # opts[:ip] = '188.129.64.124'

    # mock canada IP
    opts[:ip] = '192.206.151.131'

    flow_data = Flow.api :post, '/:organization/order-estimates', opts

    flow_data['items'].each do |item|
      sku   = item['number'].downcase
      price = item['local']['prices'].first['amount']

      @localized_order[sku] = {
        name:     item['name'],
        quantity: item['quantity'],
        price:    price,
        currency: item['local']['prices'].first['currency']
      }

    end
  end

end
