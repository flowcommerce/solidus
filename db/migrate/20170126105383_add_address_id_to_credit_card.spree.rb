# This migration comes from spree (originally 20150629175931)
class AddAddressIdToCreditCard < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_credit_cards, :address_id, :integer
  end
end
