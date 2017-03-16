# general flow helper

module FlowHelper

  def flow_flag(experience, size=32)
    exp = experience.respond_to?(:region) ? experience : FlowExperience.get(experience.key)

    return 'http://i.imgur.com/GwFYycA.png' if !exp || exp.key == 'world'

    'https://flowcdn.io/util/icons/flags/%s/%s.png' % [size, exp.region.id]
  end

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
    end

    taxon && taxon.icon_file_name ? taxon.icon.url : nil
  end

  def flow_cart_total
    return @flow_order.total_price if @flow_order
    total = nil
    if simple_current_order && simple_current_order.flow_cache['total']
      total = simple_current_order.flow_cache['total'][@flow_exp.key]
    end
    total || Flow.price_not_found
  end

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

  # used in single product page to show complete price of a product
  def product_price_long(variant)
    prices      = variant.flow_prices(@flow_exp)
    return variant.flow_spree_price unless prices.try(:first).present?

    prices.map do |price|
      label = price['label']

      case price['key']
        when 'localized_item_vat'
          '%s: %s' % [price['name'], label]
        when 'localized_item_duty'
          'duty: %s' % label
        else
          case price['includes']
            when 'vat'
              '%s incl VAT' % label
            when 'duty'
              '%s incl VAT' % label
            when 'vat_and_duty'
              '%s incl VAT and Duty' % label
            else
              label
          end
      end
    end.join(", ")
  end

  # used in checkout to show complete price breakdown
  def total_cart_breakdown
    out =  ['<table style="float: right;">']

    @flow_order.response['prices'].each do |price|
      out.push '<tr><td>%s</td><td style="text-align: right;">%s</td></tr>' % [price['key'].to_s.capitalize , price['label']]
    end

    out.push '<tr><td>%s</td><td style="text-align: right;"><b>%s</b></td></tr>' % [Spree.t(:total), flow_cart_total]

    out.push '</table>'
    out.join('').html_safe
  end

  def show_error
    return $!.message if Rails.env.developmemnt? || params[:debug]

    'error'
  end

end
