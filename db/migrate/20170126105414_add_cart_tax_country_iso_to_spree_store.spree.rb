# This migration comes from spree (originally 20160229133259)
class AddCartTaxCountryIsoToSpreeStore < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_stores, :cart_tax_country_iso, :string, null: true, default: nil
  end
end
