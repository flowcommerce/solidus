require 'spec_init'

RSpec.describe Flow do
  it 'ensures that we have at least 2 expiriences' do
    expect(Flow::EXPERIENCES.length > 1).to be(true)
  end

  it 'ensures that we have all the keys that we need' do
    exp = Flow::EXPERIENCES.first

    expect(exp[:name].length > 3).to be(true)
    expect(exp[:region][:id].length > 1).to be(true)
  end

  it 'ensures that we properly get current expirience' do
    key = Flow::EXPERIENCES.first[:region][:id]

    request = Struct.new(:subdomain, :domain, :path).new(key, 'lvh.me', '/')

    current = Flow.current_expirience(request)
    expect(current[:key]).to eq(Flow::EXPERIENCES.first[:key])
  end

  it 'ensures we can fetch flow api data' do
    data = Flow.api(:get, '/geolocation/defaults', ip: '192.206.151.131')

    expect(data[0]['country']).to eq('CAN')
  end
end
