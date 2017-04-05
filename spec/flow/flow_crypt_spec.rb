require 'spec_init'

RSpec.describe EasyCrypt do
  it 'ensures that String data can be enc & decrypted' do
    data = 'abcdefg'
    enc  = EasyCrypt.encrypt(data)
    expect(EasyCrypt.decrypt(enc)).to eq data
  end

  it 'ensures that Integer data can be enc & decrypted' do
    data = 12345678
    enc  = EasyCrypt.encrypt(data)
    expect(EasyCrypt.decrypt(enc)).to eq data
  end

  it 'fails in right excpetion for bad data' do
    enc  = EasyCrypt.encrypt('abc')
    expect{ EasyCrypt.decrypt(enc+'X') }.to raise_exception(ActiveSupport::MessageVerifier::InvalidSignature)
  end
end
