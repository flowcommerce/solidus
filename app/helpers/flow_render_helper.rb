module FlowRenderHelper

  # Renders tree on the left
  def flow_taxons_tree(root_taxon, current_taxon)
    max_level = 2
    return '' if root_taxon.children.empty?
    content_tag :ul, class: 'taxons-list' do
      taxons = root_taxon.children.map do |taxon|
        css_class = (current_taxon && current_taxon.self_and_ancestors.include?(taxon)) ? 'current' : nil
        content_tag :li, class: css_class do
          extra = nil
          extra = taxons_tree(taxon, current_taxon, max_level - 1) if taxon.id == @taxon.id
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

end