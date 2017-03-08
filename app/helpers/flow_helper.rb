# general flow helper

module FlowHelper

<<<<<<< HEAD
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
=======
  # Renders tree on the left
  def flow_taxons_tree(root_taxon, current_taxon)
    return '' if root_taxon.children.empty?

    max_level = 2

    content_tag :ul, class: 'taxons-list' do
      taxons = root_taxon.children.map do |taxon|
        css_class = (current_taxon && current_taxon.self_and_ancestors.include?(taxon)) ? 'current' : nil
        content_tag :li, class: css_class do
          extra = nil
          extra = taxons_tree(taxon, current_taxon, max_level - 1) if @taxon && [current_taxon.parent.try(:id), current_taxon.id].include?(taxon.id)
          link_to(taxon.name, seo_url(taxon)) + extra
        end
      end
      safe_join(taxons, "\n")
    end
  end

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

  # gets taxon image defined by taxonomy (category) tree
  # if icon is defined in parent, we get parent icon
  # usage: flow_category_icon @taxons[0]
  #
  # @param taxon [Spree::Taxon] - spree category
  # @return [String] - url if the custom image
  def flow_category_icon(taxon)
    icon = taxon.icon_file_name

    while icon.blank? && (taxon = taxon.parent)
      icon = taxon.icon_file_name
>>>>>>> dev
    end

    taxon && taxon.icon_file_name ? taxon.icon.url : nil
  end

<<<<<<< HEAD
=======
  def flow_cart_total
    order = @order || simple_current_order
    order.flow_cache['total'][@flow_exp.currency]
  rescue
    'n/a ?'
  end

>>>>>>> dev
  # this renders link to cart with total cart price
  def flow_link_to_cart(text=nil)
    text = text ? h(text) : Spree.t(:cart)

    # r @flow_exp
    # r simple_current_order

    if simple_current_order.nil? || simple_current_order.item_count.zero?
      text = '%s: (%s)' % [text, Spree.t(:empty)]
      css_class = :empty
    else
      text = '%s: (%s) <span class="amount">%s</span>' % [text, simple_current_order.item_count, flow_cart_total]
      css_class = :full
    end

    link_to text.html_safe, spree.cart_path, class: 'cart-info %s' % css_class
  end

  def flow_normalize_categories(taxonomy_string)
    taxonomy_string.sub('<li itemprop="itemListElement" itemscope="itemscope" itemtype="https://schema.org/ListItem"><a itemprop="item" href="/products"><span itemprop="name">Products</span><meta itemprop="position" content="2" /></a>&nbsp;&raquo;&nbsp;</li>','').html_safe
  end

  # gets jumbo image, returns nil unless found, no default
  def flow_get_jumbo_image
    if !params[:page] && request.path == '/'
      '/jumbo/home.jpg'
    else
      return nil unless @taxon
      image = @taxon.icon(:original)
      image.include?('default_taxon.png') ? nil : image
    end
  end

  # get flow item from line item and shows localized price
  # used in app/views/spree/orders/_line_item.html.erb
  # old: line_item.single_money.to_html
  def flow_line_item_price(line_item, quantity=nil)
    # will localize only once unless localized
<<<<<<< HEAD
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
=======
    variant = line_item.variant
    prices  = variant.flow_prices(@flow_exp)

    return variant.flow_rescue_price(quantity) unless prices

    return prices[0]['label'] unless quantity

    total_amount = prices[0]['amount'] * quantity

    '%.2f %s' % [total_amount, @flow_exp.currency]
  end

  def product_price_long(variant)
    variant.flow_prices.map { |price|
      case price.key
     when "localized_item_price"
       case price.includes
         when "vat"
           "%s incl VAT" % price.label
         when "duty"
           "%s incl VAT" % price.label
         when "vat_and_duty"
           "%s incl VAT and Duty" % price.label
       else
           price.label
       end
         
     when "localized_item_vat"
       "#{price.name}: #{price.label}"
>>>>>>> dev

      when "localized_item_duty"
       "Duty: #{price.label}"
     end
     }.join(", ")
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
