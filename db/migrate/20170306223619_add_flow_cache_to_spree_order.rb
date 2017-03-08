class AddFlowCacheToSpreeOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :spree_orders, :flow_cache, :jsonb, default: {}
  end
end
