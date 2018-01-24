require 'spec_init'

RSpec.describe Flow do
  let(:session_instance) {
    Flow::Session.new(ip: '192.206.151.131', visitor: 'test_user_UID').tap do |session|
      session.create
    end
  }

  it 'checks that we can gets canadian session from flow' do
    expect(session_instance.session.organization).to eq(Flow.organization)
    expect(session_instance.session.local.country.name).to eq('Canada')
  end

  it 'checks session dump/restore' do
    dump     = Base64.encode64(session_instance.dump)
    restored = Flow::Session.restore Base64.decode64(dump)

    expect(restored.session.ip).to eq(session_instance.session.ip)
    expect(restored.session.organization).to eq(session_instance.session.organization)
  end

  it 'expects class variabes to be set' do
    expect(Flow.organization.present?).to be_truthy
    expect(Flow.base_country.present?).to be_truthy
    expect(Flow.api_key.present?).to      be_truthy
  end

end
