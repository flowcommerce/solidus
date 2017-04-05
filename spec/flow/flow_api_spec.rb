require 'spec_init'

RSpec.describe Flow do

  it 'checks that we can gets canadian session from flow' do
    flow_session = FlowSession.new ip: '192.206.151.131'

    expect(flow_session.session.organization).to eq(ENV.fetch('FLOW_ORGANIZATION'))
    expect(flow_session.session.local.country.name).to eq('Canada')
  end

end
