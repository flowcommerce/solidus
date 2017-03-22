# Flow.io (2017)
# Module uses rails engine for encrypt and decrypt


module FlowCrypt
  extend self

  def encrypt_base
    ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0,32])
  end

  def encrypt(raw_data)
    encrypt_base.encrypt_and_sign(raw_data)
  end

  def decrypt(enc_data)
    encrypt_base.decrypt_and_verify(enc_data)
  end
end