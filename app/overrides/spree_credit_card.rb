# added flow specific methods to Spree::CreditCard

Spree::CreditCard.class_eval do

  before_save :flow_fetch_cc_token

  def flow_fetch_cc_token
    # build cc hash
    data = {}
    data[:number]           = number
    data[:name]             = name
    data[:cvv]              = verification_value
    data[:expiration_year]  = year
    data[:expiration_month] = month

    # result = FlowRoot.api :post, '/:organization/cards', BODY: data
    card_form = ::Io::Flow::V0::Models::CardForm data
    result    = FlowCommerce.instance.cards.post(ENV.fetch('FLOW_ORG'), card_form)
    result    = FlowCommerce.org.cards.post(card_form)

    # cache the result
    flow_cache['cc_token'] = result.token

    true
  end

end

