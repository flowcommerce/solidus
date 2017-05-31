# Flow (2017)
# Enable this modifications if you want to display flow localized line item
# and total prices beside Solidus/Spree default
# Example: https://i.imgur.com/7v2ix2G.png

Spree::LineItem.class_eval do
  # admin show line item price
  def single_money
    price  = display_price.to_s
    price += ' (%s)' % order.flow_line_item_price(self) if order.flow_order
    price
  end
end

###

Spree::Order.class_eval do
  alias :old_display_total :display_total
  def display_total
    price = old_display_total.to_s
    price += ' (%s)' % flow_total if flow_order
    price.html_safe
  end
end

###

module Spree::Admin::OrdersHelper
  # admin show line item total price
  alias :old_line_item_shipment_price :line_item_shipment_price
  def line_item_shipment_price(line_item, quantity)
    # r @order
    price = old_line_item_shipment_price(line_item, quantity).to_s
    price += ' (%s)' % @order.flow_line_item_price(line_item, quantity) if @order.flow_order
    price.html_safe
  end
end
