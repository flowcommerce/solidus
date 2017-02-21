module FlowHelper
  # Ads markdown like rendering to product descripton
  #
  # @param product [Spree::Product] the product whose description you want to filter
  # @return [String] the generated HTML
  def flow_product_description(product)
    return raw(product.description) if Spree::Config[:show_raw_product_description]

    data = product.description
    data.gsub!(/^[\s\*]+/, '* ')
    data.gsub!(/\n\s*\*\s+/, "\n\n* ")

    # abandonded, do not use.
    # red_carpet = Redcarpet::Render::HTML.new(no_style: true)
    # markdown   = Redcarpet::Markdown.new(red_carpet, {})
    # return markdown.render(data).html_safe

    data = ' '+raw(product.description.gsub(/(.*?)\r?\n\r?\n/m, '<p>\1</p>'))
    data.gsub!(' *', '<li>')

    parts = data.split('<li>', 2)
    parts[0] = '<p>%s</p>' % parts[0] if parts[0] =~ /\w/

    parts.join('<li>').html_safe
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
    quantity = 1 if quantity.to_i < 1

    total = if line_item.is_a?(Hash)
      line_item[:price] * quantity
    else
      sku = line_item.variant.sku
      flow_product = FlowCatalogCache.load_by_country_and_sku(@flow_exp, sku)
      flow_product[:amount] * quantity
    end

    Flow.format_price(total, @flow_exp)
  end

  # get default image path for product
  # /app/models/spree/image.rb
  def get_default_image_from_variant(variant)
    if variant.images.length == 0
      variant.product.display_image.attachment(:small)
    else
      variant.images.first.attachment.url(:small)
    end
  end

  # get data from local order
  def flow_localize_cart_from_spree
    @order.line_items.each do |product|
      variant = product.variant

      @localized_order.push({
        number:   variant.sku.downcase,
        name:     "Gold-tone brass crocodile cuff bracelet",
        quantity: product.quantity,
        price:    product.price,
        image:    get_default_image_from_variant(variant),
        path:     product_path(product)
      })
    end
  end

  # get data from flow api
  def flow_localize_cart_from_flow
    items = []
    product_data = {}

    @order.line_items.each do |product|
      variant = product.variant
      sku     = variant.sku

      # data we want to extract from spree order and pas to @localized_order
      product_data[sku.downcase] = {
        image: get_default_image_from_variant(variant),
        path:  product_path(product)
      }

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

    # canada
    opts[:ip] = '192.206.151.131'

    flow_data = Flow.api :post, '/:organization/order-estimates', opts

    flow_data['items'].each do |item|
      sku = item['number'].downcase
      object = {
        number:   sku,
        name:     item['name'],
        quantity: item['quantity'],
        price:    item['local']['prices'].first['amount'],
      }

      object.merge! product_data[sku] if product_data[sku]

      @localized_order.push object
    end
  end

  # localizes order items
  # we will use this order items to show products in cart, insted of
  # spree default line items
  def flow_localize_cart
    @localized_order = []

    raise 'Supported "source" values are :spree and :flow' if params[:source] && !['spree', 'flow'].include?(params[:source])

    case params[:source]
      when 'spree'
        flow_localize_cart_from_spree
      when 'flow'
        flow_localize_cart_from_spree
      else
        flow_localize_cart_from_flow
    end

    @localized_order
  end

end
