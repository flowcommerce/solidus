# core function overload, probably not needed for our custumers

Spree::Order.class_eval do

  # lever here for now
  # def total
  #   [:item_total, :adjustment_total, :included_tax_total, :additional_tax_total, :tax_total, :shipment_total, :promo_total].inject(0) do |total, el|
  #     total + send(el)
  #   end
  # end

end