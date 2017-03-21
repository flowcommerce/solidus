class AddFlowFields < ActiveRecord::Migration[5.0]
  def add_field_unless_exists(table, field, type, opts={})
    unless column_exists? table, field
      add_column table, field, type, opts
    end
  end

  def up
    add_field_unless_exists :spree_orders, :flow_number, :string
    add_field_unless_exists :spree_variants, :flow_cache, :jsonb, default: {}
    add_field_unless_exists :spree_orders, :flow_cache, :jsonb, default: {}
    add_field_unless_exists :spree_credit_cards, :flow_cache, :jsonb, default: {}
  end
end
