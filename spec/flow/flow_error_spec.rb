require 'spec_init'
require 'flowcommerce'

class TestError < StandardError

end

RSpec.describe Flow::Error do
  let(:request) { Struct.new(:url).new('http://mock/flow') }

  let(:flow_error) {
    Io::Flow::V0::HttpClient::ServerError.new(500, 'foo', body: '{"messages":["b","a","r"]}')
  }

  ###

  it 'formats message in right way' do
    formated = Flow::Error.format_message(flow_error)
    expect(formated[:message]).to eq('b, a, r')

    not_formated = Flow::Error.format_message(StandardError.new('foo'))
    expect(not_formated[:message]).to eq('foo')
  end

  it 'ensures that errors are logged' do
    # if bugsnag is installed, it will probably log
    require 'bugsnag'

    expect(Bugsnag.to_s).to eq('Bugsnag')
    expect(Bugsnag.respond_to?(:notify)).to eq(true)
  end
end
