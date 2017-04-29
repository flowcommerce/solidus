# core function overload, probably not needed for our custumers

Spree::Order.class_eval do

  # spree calcualtes wrong item total, this fixes it
  def item_total
    line_items.inject(0) { |total, line_item| total += line_item.amount * line_item.quantity; total }
  end

  # full total has to be fixed as well
  def total
    [:item_total, :adjustment_total, :included_tax_total, :additional_tax_total, :tax_total, :shipment_total, :promo_total].inject(0) do |total, el|
      total + send(el)
    end
  end

end