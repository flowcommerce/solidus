# general flow helper

module FlowHelper

  def flow_flag exp, size=32
    return 'http://i.imgur.com/GwFYycA.png' if exp && exp.key == 'world'

    flag = unless exp
      'usa'
    else
      exp = Flow::Experience.get(exp.key) unless exp.respond_to?(:region)
      exp.region.id
    end

    'https://flowcdn.io/util/icons/flags/%s/%s.png' % [size, flag]
  end

  def flow_tag name, opts={}
    data = if [:input, :img, :hr, :br].include?(name)
      nil
    else
      block_given? ? yield : ''
    end

    data = data.join('') if data.is_a?(Array)

    node = "<#{name}#{tag_options(opts)}"
    node += data ? ">#{data}</#{name}>" : ' />'
    node.html_safe
  end

  def flow_product_price product_or_variant
    if @flow_session.use_flow?
      product_or_variant.flow_local_price @flow_exp
    else
      product_or_variant.price_for(current_pricing_options).to_html
    end
  end

  def flow_show_product_price
    if @flow_session.use_flow?
      @variants.each.inject({}) { |h, v| h[v.id] = product_price_long(v); h }.to_json.html_safe
    else
      { @variants.first.id=>display_price(@product) }.to_json.html_safe
    end
  end

  # Renders tree on the left
  def flow_taxons_tree root_taxon, current_taxon
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
  def flow_product_description product
    return raw(product.description) if Spree::Config[:show_raw_product_description]

    data = product.description
    data.gsub! /^[\s\*]+/, '* '
    data.gsub! /\n\s*\*\s+/, "\n\n* "

    # abandonded, do not use.
    # red_carpet = Redcarpet::Render::HTML.new(no_style: true)
    # markdown   = Redcarpet::Markdown.new(red_carpet, {})
    # return markdown.render(data).html_safe

    data = ' ' + raw(product.description.gsub(/(.*?)\r?\n\r?\n/m, '<p>\1</p>'))
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
  def flow_category_icon taxon
    icon = taxon.icon_file_name

    while icon.blank? && (taxon = taxon.parent)
      icon = taxon.icon_file_name
    end

    taxon && taxon.icon_file_name ? taxon.icon.url : nil
  end

  # this renders link to cart with total cart price
  def flow_link_to_cart text=nil
    text ||= Spree.t(:cart)

    order = @order || simple_current_order
    order = nil if order && (order.state == 'complete' || order.item_count.zero?)

    if order.nil?
      text = '%s: (%s)' % [text, Spree.t(:empty)]
      css_class = :empty
    else
      text = '%s: (%s) <span class="amount">%s</span>' % [text, order.item_count, order.flow_total]
      css_class = :full
    end

    link_to text.html_safe, spree.cart_path, class: 'cart-info %s' % css_class
  end

  def flow_normalize_categories taxonomy_string
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

  # used in single product page to show complete price of a product
  def product_price_long variant
    prices = variant.flow_prices @flow_exp
    return variant.flow_spree_price unless prices.try(:first).present?

    prices.map do |price|
      label = price['label']

      case price['key']
        when 'localized_item_vat'
          '%s: %s' % [price['name'], label]
        when 'localized_item_duty'
          'duty: %s' % label
        else
          if price['includes']
            '%s (%s)' % [label, price['includes']['label']]
          else
            label
          end
      end
    end.join(', ')
  end

  # used in checkout and mailer to show complete price breakdown
  def total_cart_breakdown
    cart_data = @order.flow_cart_breakdown

    last = cart_data[cart_data.length - 1]
    last[1] = '<b>%s</b>' % last[1]

    out =  ['<table style="float: right;">']

    cart_data.each do |price|
      out.push '<tr><td>%s</td><td style="text-align: right;">%s</td></tr>' % [price.name , price.label]
    end

    out.push '</table>'
    out.join('').html_safe
  rescue
    @has_order_error = true

    show_error 'cart error'
  end

  def show_error message=nil
    Flow::Error.log $!, request

    '<div class="flash error">%s</div>'.html_safe % $!.message
  end

  def flow_top_nav_data
    data = ['using flow (%s)' % @flow_exp.key]

    if respond_to?(:simple_current_order) && simple_current_order.number
      text = simple_current_order.number

      if @current_spree_user.try(:admin?)
        text  = link_to text, '/admin/orders/%s/edit' % text
        text += ', <a href="https://console.flow.io/%s/orders/%s" target="_console">console</a>'.html_safe % [Flow.organization, simple_current_order.number]
        text += ', <a href="/admin/flow?flow=order&o_id=%s" target="_api">api</a>'.html_safe % [simple_current_order.id]
      end

      data.push 'Order (%s)' % text
    end

    if @variants && @current_spree_user.try(:admin?)
      admin_link  = '/admin/products/%s/variants' % @product.slug
      variant_ids = @variants.map { |o| link_to(o.id, 'https://console.flow.io/%s/catalog/items/%d' % [Flow.organization, o.id], target: '_new_%d' % o.id) }.join(', ')

      data.push 'Variant IDs (%s) <a href="%s">admin</a>' % [variant_ids, admin_link]
    end

    data.reverse.join(' | ').html_safe
  end

  def flow_build_main_menu
    flow_tag(:ul) do
      # 1.st lvl menu
      Spree::Taxonomy.all.collect do |taxonomy|
        flow_tag :li do
          # link_to(taxonomy.name, '/t/%s' % taxonomy.taxons.first.permalink) +
          main_link = nil

          # 2.nd lvl menu
          sub_data = flow_tag(:ul) do
            Spree::Taxon.where(taxonomy_id: taxonomy.id, depth: 1).collect do |taxon|
              main_link ||= '/t/%s' % taxon.permalink.split('/').first

              flow_tag :li do
                link_to taxon.name, '/t/%s' % taxon.permalink
              end
            end
          end

          link_to(taxonomy.name, main_link) + sub_data
        end
      end
    end.html_safe
  end

  def svg_ico path, opts={}
    ico = Rails.root.join('./public%s' % path).read
    ico.sub!(/#\{(\w+)\}/) { opts[$1.to_sym] }
    ico.html_safe
  end

end
