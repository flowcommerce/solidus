require 'spec_init'

RSpec.describe Flow do
  it 'ensures that spree_order has flow_number' do
    expect(Spree::Order.columns_hash['flow_number'].sql_type).to eq('character varying')
  end

  it 'ensures that spree has all needed cache fields' do
    expect(Spree::Order.columns_hash['flow_data'].sql_type).to eq('jsonb')
    expect(Spree::Variant.columns_hash['flow_data'].sql_type).to eq('jsonb')
  end

end
