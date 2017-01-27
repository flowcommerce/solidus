# This migration comes from spree (originally 20151021113730)
class AddSaleToSpreePromotions < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_promotions, :apply_automatically, :boolean, default: false
    add_index :spree_promotions, :apply_automatically
  end
end
