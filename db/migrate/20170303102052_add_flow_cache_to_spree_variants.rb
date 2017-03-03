class AddFlowCacheToSpreeVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :spree_variants, :flow_cache, :jsonb, default: {}
  end
end
