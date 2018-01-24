class CreateFlowSettings < ActiveRecord::Migration[5.0]
  def change
    unless table_exists?(:flow_settings)
      create_table :flow_settings do |t|
        t.string :key
        t.text :data
        t.datetime :created_at
      end
    end
  end
end
