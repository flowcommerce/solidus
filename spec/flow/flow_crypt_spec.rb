require 'spec_init'

RSpec.describe Flow::SimpleCrypt do
  it 'ensures that String data can be enc & decrypted' do
    data = 'abcdefg'
    enc  = Flow::SimpleCrypt.encrypt(data)
    expect(Flow::SimpleCrypt.decrypt(enc)).to eq data
  end

  it 'ensures that Integer data can be enc & decrypted' do
    data = 12345678
    enc  = Flow::SimpleCrypt.encrypt(data)
    expect(Flow::SimpleCrypt.decrypt(enc)).to eq data
  end

  it 'fails in right excpetion for bad data' do
    enc  = Flow::SimpleCrypt.encrypt('abc')
    expect{ Flow::SimpleCrypt.decrypt(enc+'X') }.to raise_exception(ActiveSupport::MessageVerifier::InvalidSignature)
  end
end
