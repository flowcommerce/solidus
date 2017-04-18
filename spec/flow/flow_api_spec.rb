require 'spec_init'

RSpec.describe Flow do

  it 'checks that we can gets canadian session from flow' do
    flow_session = Flow::Session.new ip: '192.206.151.131'

    expect(flow_session.session.organization).to eq(Flow.orgnization)
    expect(flow_session.session.local.country.name).to eq('Canada')
  end

end
