# added flow specific methods to Spree::Variant

Spree::Product.class_eval do

  def flow_number
    variants.first.flow_number
  end

  # returns [amount, currency] from master variant
  def flow_raw_price(experience)
    variants.first.flow_raw_price(experience)
  end

  # returns price tied to local experience from master variant
  def flow_local_price(experience)
    variants.first.flow_local_price(experience)
  end

end

