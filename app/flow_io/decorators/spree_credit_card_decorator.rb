# added flow specific methods to Spree::CreditCard

Spree::CreditCard.class_eval do

  validate :flow_fetch_cc_token

  def flow_fetch_cc_token
    return false if flow_cache['cc_token']
    return false unless number
    return errors.add(:verification_value, 'CVV verification value is required') unless verification_value.present?

    # build cc hash
    data = {}
    data[:number]           = number
    data[:name]             = name
    data[:cvv]              = verification_value
    data[:expiration_year]  = year.to_i
    data[:expiration_month] = month.to_i

    card_form = ::Io::Flow::V0::Models::CardForm.new(data)
    result    = FlowCommerce.instance.cards.post(Flow.organization, card_form)

    # cache the result
    flow_cache['cc_token'] = result.token

    true
  rescue Io::Flow::V0::HttpClient::ServerError
    puts $!.message
    flow_error = $!.message.split(':', 2).first
    errors.add(:base, flow_error)
  end

end

