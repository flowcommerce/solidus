module FlowHelper
  # Ads markdown rendering to product descripton
  #
  # @param product [Spree::Product] the product whose description you want to filter
  # @return [String] the generated HTML
  def flow_product_description(product)
    data = ' '+raw(product.description.gsub(/(.*?)\r?\n\r?\n/m, '<p>\1</p>'))
    data.gsub!(' *', '<li>')
    data.html_safe
  end

  # shows flow harmoniszed price of the product
  def flow_price(product)
    Flow.render_price_from_flow(@flow_exp, product)
  end

end
