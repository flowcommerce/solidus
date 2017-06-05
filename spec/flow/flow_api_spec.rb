require 'spec_init'

RSpec.describe Flow do

  it 'checks that we can gets canadian session from flow' do
    flow_session = Flow::Session.new ip: '192.206.151.131'

    expect(flow_session.session.organization).to eq(Flow.organization)
    expect(flow_session.session.local.country.name).to eq('Canada')
  end

  it 'expects class variabes to be set' do
    expect(Flow.organization.present?).to be_truthy
    expect(Flow.base_country.present?).to be_truthy
    expect(Flow.api_key.present?).to      be_truthy
  end

end
