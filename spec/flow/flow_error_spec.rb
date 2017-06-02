require 'spec_init'

class TestError < StandardError

end

RSpec.describe Flow::Error do
  let(:request) { Struct.new(:url).new('http://mock/flow') }

  let(:flaw_order) {
    {
      'messages' => ['first error', 'second error']
    }
  }

  ###

  it 'formats message in right way' do
    formated = Flow::Error.format_message flaw_order
    expect(formated).to eq('first error, second error (Flow.io)')

    not_formated = Flow::Error.format_message({})
    expect(not_formated).to eq('Order not properly localized (sync issue) (Flow.io)')
  end

  it 'ensures that errors are logged' do
    message = 'flow mock error'

    # clear all test errors
    FileUtils.rm_rf('./log/exceptions/test_errors/.', secure: true)

    begin
      raise TestError.new message
    rescue TestError => e
      Flow::Error.log e, request
    end

    error_files = Dir['./log/exceptions/test_errors/*']
    expect(error_files.length).to eq(1)
    expect(File.read(error_files.first).include?(message)).to be_truthy
  end
end
