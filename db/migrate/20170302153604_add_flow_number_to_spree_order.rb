class AddFlowNumberToSpreeOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :spree_orders, :flow_number, :string
  end
end
