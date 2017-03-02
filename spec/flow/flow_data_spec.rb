require 'spec_init'

RSpec.describe Flow do
  it 'ensures that spree_order has flow_number' do
    flow_number = 'foo-123'

    spree_order = Spree::Order.new
    spree_order[:flow_number] = flow_number
    expect(spree_order.flow_number).to eq(flow_number)
  end
end
