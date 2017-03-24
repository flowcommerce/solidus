# added flow specific methods to Spree::CreditCard

Spree::CreditCard.class_eval do

  validate :flow_fetch_cc_token

  def flow_fetch_cc_token
    return if flow_cache['cc_token']
    return unless verification_value

    # build cc hash
    data = {}
    data[:number]           = number
    data[:name]             = name
    data[:cvv]              = verification_value
    data[:expiration_year]  = year.to_i
    data[:expiration_month] = month.to_i

    card_form = ::Io::Flow::V0::Models::CardForm.new(data)
    result    = FlowCommerce.instance.cards.post(ENV.fetch('FLOW_ORG'), card_form)

    # cache the result
    flow_cache['cc_token'] = result.token

    true
  rescue Io::Flow::V0::HttpClient::ServerError
    puts $!.message
    flow_error = $!.message.split(':', 2).first
    errors.add(:base, flow_error)
  end

end

