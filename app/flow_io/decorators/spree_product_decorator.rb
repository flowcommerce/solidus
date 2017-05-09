# added flow specific methods to Spree::Variant

Spree::Product.class_eval do

  # returns price tied to local experience from master variant
  def flow_local_price(flow_exp)
    variants.first.flow_local_price(flow_exp)
  end

  def flow_included?(flow_exp)
    return true unless flow_exp
    flow_data['%s.excluded' % flow_exp.key].to_i == 1 ? false : true
  end

end

