# general flow helper

module FlowHelper
  extend self

  # <% if @jumbo_image = flow_get_jumbo_image %>
  #   <div id="jumbo-image">
  #     <img src="<%= @jumbo_image %>" />
  #   </div>
  # <% end %>
  def flow_render_header
    banner = case request.path
      when '/'
        {
          url:   'http://i.imgur.com/9EnpmO7.jpg', # :homepage
          title: 'Adventure awaits',
          desc:  'Vacation ready coats and boots'
        }
      when '/sale'
        {
          url:   'http://i.imgur.com/KlgPyTV.jpg', # :sale
          title: 'Sale',
          desc:  'Last chance on summer steals'
        }
      when '/t/apparel-and-accessories/shoes'
        {
          url:   'http://i.imgur.com/0za1RWv.jpg', # :accessories
          title: 'Wherever you go',
          desc:  'Durable footwear for an active life'
        }
      when '/t/apparel-and-accessories'
        {
          url:   'http://i.imgur.com/WYjqXMp.jpg', # :clothing
          title: 'Lived-in fashion',
          desc:  'Travel with comfort and style'
        }
      when '/t/luggage-and-bags'
        {
          url:   'http://i.imgur.com/z58J56Q.jpg', # :lugage
          title: 'Ready for the road',
          desc:  'Luggage and accessories to go where you do'
        }
    end

    return unless banner

    %[<div id="jumbo-top">
        <img src="#{banner[:url]}" style="display: block !important;" />
      </div>
      <div id="jumbo-top-text" class="container">
        <h2>#{banner[:title]}</h2>
        <h3>#{banner[:desc]}</h3>
      </div>].html_safe
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

  def flow_flag experience, size=32
    return '/images/world.png' if experience && experience.key == 'world'

    flag = unless experience
      'usa'
    else
      experience = Flow::Experience.get(experience.key) unless experience.respond_to?(:region)
      experience.country.downcase
    end

    'https://flowcdn.io/util/icons/flags/%s/%s.png' % [size, flag]
  end

  def flow_tag name, opts={}
    data = if [:input, :img, :hr, :br].include?(name)
      nil
    else
      block_given? ? yield(opts) : ''
    end

    data = data.join('') if data.is_a?(Array)

    node = "<#{name}#{tag_options(opts)}"
    node += data ? ">#{data}</#{name}>" : ' />'
    node.html_safe
  end

  def flow_product_price product_or_variant
    if @flow_session.use_flow?
      product_or_variant.flow_local_price @flow_session.experience
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

  def flow_cart_ico
    order = @order || simple_current_order
    order = nil if order && (order.state == 'complete' || order.item_count.zero?)

    count = order.nil? ? '-' : order.item_count
    color = order.nil? ? '#000000' : '#880000'

    svg_ico '/images/nav-bag.svg', count: count, color: color
  end


  def flow_normalize_categories taxonomy_string
    taxonomy_string.sub('<li itemprop="itemListElement" itemscope="itemscope" itemtype="https://schema.org/ListItem"><a itemprop="item" href="/products"><span itemprop="name">Products</span><meta itemprop="position" content="2" /></a>&nbsp;&raquo;&nbsp;</li>','').html_safe
  end

  # used in single product page to show complete price of a product
  def product_price_long variant
    prices = variant.flow_prices @flow_session.experience
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
  def total_cart_breakdown style=nil
    cart_data = @order.flow_cart_breakdown

    last = cart_data[cart_data.length - 1]
    last[1] = '<b>%s</b>' % last[1]

    style ||= "float: right;"
    out   =  ["<div id='total-cart-breakdown' style='#{style}'><table>"]

    cart_data.each do |price|
      name = price.name
      name = '<b>%s</b>' % name if name == 'Total'
      out.push '<tr><td>%s</td><td style="text-align: right;">%s</td></tr>' % [price.name , price.label]
    end

    out.push '</table></div>'
    out.join('').html_safe
  end

  def show_error message=nil
    Flow::Error.log $!, request

    '<div class="flash error">%s</div>'.html_safe % $!.message
  end

  def flow_top_nav_data
    data = [
      'using flow (<a href="https://console.flow.io/%{org}/experience/%{key}/localization" target="_console">%{key}</a>)' %
      { org: Flow.organization, key: @flow_session.experience.key }
    ]

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
      main_data = Spree::Taxonomy.all.collect do |taxonomy|
        flow_tag :li do |opts|
          # link_to(taxonomy.name, '/t/%s' % taxonomy.taxons.first.permalink) +
          main_link = nil

          # 2.nd lvl menu
          sub_data = flow_tag(:ul) do
            Spree::Taxon.where(taxonomy_id: taxonomy.id, depth: 1).collect do |taxon|
              main_link ||= taxon.permalink.split('/').first

              flow_tag :li do
                link_to taxon.name, '/t/%s' % taxon.permalink
              end
            end
          end

          opts[:class] = 'active' if request.path.include?(main_link)

          link_to(taxonomy.name, '/t/%s' % main_link) + sub_data
        end
      end

      main_data.push %[<li><a href="/sale">Sale</a></li>]

      main_data
    end.html_safe
  end

  def svg_ico path, opts={}
    ico = Rails.root.join('./public%s' % path).read
    ico = ico.gsub(/#\{(\w+)\}/) { opts[$1.to_sym] }
    ico.html_safe
  end

  def flow_options_decorate text
    text.gsub(/(\w+):/, '<b>\1</b>:').gsub(', ', '<br />').html_safe
  end

  def show_promotion
    return unless @flow_session.experience

    promo = ActiveRecord::Base.connection.execute("
      select *
      from spree_promotions
      where
        advertise=true
        and name ilike '% top %'
        and flow_data->'filter'->'experience' ? '#{@flow_session.experience.key}'
    ").first

    return unless promo

    data  = promo['description'].upcase
    data  = '<a href="%s">%s</a>' % [promo['path'], data] if promo['path']
    data  = '<div id="top-promo">%s</div>' % data

    data.html_safe
  end

end
