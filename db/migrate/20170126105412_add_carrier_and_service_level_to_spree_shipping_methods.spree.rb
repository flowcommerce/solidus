# This migration comes from spree (originally 20160122182105)
class AddCarrierAndServiceLevelToSpreeShippingMethods < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_shipping_methods, :carrier, :string
    add_column :spree_shipping_methods, :service_level, :string
  end
end
