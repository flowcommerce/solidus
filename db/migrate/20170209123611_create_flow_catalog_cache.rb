class CreateFlowCatalogCache < ActiveRecord::Migration[5.0]
  def change
    create_table :flow_catalog_caches do |t|
      t.string   :sku
      t.string   :country
      t.string   :remote_id
      t.jsonb    :data
      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index(:flow_catalog_caches, [:sku, :country])
  end
end
