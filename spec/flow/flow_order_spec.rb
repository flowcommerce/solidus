require 'spec_init'

class OrderMock
  attr_accessor :flow_data

  def number
    'ON1'
  end

  def flow_order
    return nil unless flow_data['order']
    Hashie::Mash.new flow_data['order']
  end

  def flow_data
    {
      'order' => {
        'selections' => ['opt-df5144291ce04a38a30c898187cb8392'],
        'experience' => {'key' => 'canada'},
        'deliveries' => [
          {
            'id' => 'del-3eb4cba9c477438d9d2c56e4be5459a2',
            'options' => [
              {
                'id'   => 'opt-df5144291ce02a38a30c898187cb8391',
                'tier' => {
                  'name'     => 'wolly mamuth',
                  'strategy' => ['landmark-global']
                },
                'price' => {
                  'label' => 'CA$12.34'
                }
              },
              {
                'id'   => 'opt-df5144291ce04a38a30c898187cb8392',
                'tier' => {
                  'name'     => 'tesla',
                  'strategy' => ['dhl']
                },
                'price' => {
                  'label' => 'CA$12.34'
                }
              }
            ]
          }
        ]
      }
    }
  end
end

RSpec.describe Flow::Order do

  let(:order) { OrderMock.new }

  it 'renders error message' do
    flow_order = Flow::Order.new order: order

    expect(flow_order.error?).to be_nil

    flow_order.instance_eval do
      @response = { 'code' => 'test_error', 'messages' => 'Ruby is on fire' }
    end

    expect(flow_order.error?).to eq 'Ruby is on fire'
  end

  it 'selects first active delivery' do
    flow_order = Flow::Order.new order: order

    delivery = flow_order.delivery

    expect(delivery[:id]).to eq 'opt-df5144291ce04a38a30c898187cb8392'
  end

end
