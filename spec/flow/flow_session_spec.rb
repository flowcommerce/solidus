require 'spec_init'

RSpec.describe Flow::Session do
  let(:test_session) {
    {
      "id"            => "F51ZH1U6D1raEWT9wFDFaWoqApqfAWpWRWdd2JtAjtzI2HuxlmOvxrcBAa7iPsoO",
      "organization"  => Flow.organization,
      "environment"   => "sandbox",
      "attributes"    => {},
      "ip"            => "127.0.0.1",
      "local"         => nil,
      "discriminator" => "organization_session"
    }
  }

  ###

  it 'creates right session from IP' do
    canada_ip     = '192.206.151.131'
    flow_seession = Flow::Session.new ip: canada_ip

    expect(flow_seession.local.experience.name).to eq 'Canada'
    expect(flow_seession.localized?).to be_truthy
  end

  it 'creates session from hash' do
    flow_seession = Flow::Session.new hash: test_session

    expect(flow_seession.session.id).to eq test_session['id']
  end


  it 'expects error when not seding parameters to session' do
    expect { Flow::Session.new }.to raise_error ArgumentError
  end
end
