# This migration comes from spree (originally 20150121202544)
class AddRestockInventoryToStockLocation < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_stock_locations, :restock_inventory, :boolean, default: true, null: false
  end
end
