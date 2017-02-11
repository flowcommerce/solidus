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
    variant    = product.variants.first
    flow_cache = FlowCatalogCache.load_by_country_and_sku @flow_exp.country, variant.sku.downcase

    if flow_cache
      data = '%s %s' % [number_with_delimiter(flow_cache['amount']), @flow_exp.currency]
      data
    else
      # flow catalog item not found, revert to base for now
      # in the future, cache conversion rates, live price calculate
      display_price(product)
    end
  end

end
