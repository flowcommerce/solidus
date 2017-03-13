require 'spec_init'

RSpec.describe Flow::Crypt do
  it 'ensures that String data can be enc & decrypted' do
    data = 'abcdefg'
    enc  = Flow::Crypt.encrypt(data)
    expect(Flow::Crypt.decrypt(enc)).to eq data
  end

  it 'ensures that Integer data can be enc & decrypted' do
    data = 12345678
    enc  = Flow::Crypt.encrypt(data)
    expect(Flow::Crypt.decrypt(enc)).to eq data
  end

  it 'fails in right excpetion for bad data' do
    enc  = Flow::Crypt.encrypt('abc')
    expect{ Flow::Crypt.decrypt(enc+'X') }.to raise_exception(ActiveSupport::MessageVerifier::InvalidSignature)
  end
end
