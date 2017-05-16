# Flow.io (2017)
# Module uses rails engine for encrypt and decrypt

# example
# enc1 = Flow::SimpleCrypt.encrypt('foo')
# Flow::SimpleCrypt.encrypt(enc1)
#
# example with salt
# enc2 = Flow::SimpleCrypt.encrypt('bar', '127.0.0.1')
# Flow::SimpleCrypt.encrypt(enc2)              # raises error: ActiveSupport::MessageVerifier::InvalidSignature
# Flow::SimpleCrypt.encrypt(enc2, '127.0.0.1') # ok

module SimpleCrypt
  extend self

  def encrypt_base(salt)
    local_secret = Rails.application.secrets.secret_key_base[0,32]
    key          = ActiveSupport::KeyGenerator.new(local_secret).generate_key(salt || '', 32)

    ActiveSupport::MessageEncryptor.new(key)
  end

  def encrypt(raw_data, salt=nil)
    encrypt_base(salt).encrypt_and_sign(raw_data)
  end

  def decrypt(enc_data, salt=nil)
    encrypt_base(salt).decrypt_and_verify(enc_data)
  end
end