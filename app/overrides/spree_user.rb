# added flow specific methods to Spree::User
# which is for spree / solidus in same time
# - user object (for admins as well)
# - customer object

Spree::User.class_eval do

  def flow_number
    return unless id

    token = ENV.fetch('SECRET_TOKEN')
    's-u-%s' % Digest::SHA1.hexdigest('%d-%s' % [id, token])
  end

end

