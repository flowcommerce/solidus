# Flow.io (2017)
# flow api helper

module Flow::Api
  extend self

  # adds cc and gets cc token
  def add_card cc_hash:, credit_card:
    raise ArgumentError, 'Credit card card class is not %s' % Spree::CreditCard unless credit_card.class == Spree::CreditCard

    # {"cvv":"737","expiration_month":8,"expiration_year":2018,"name":"Joe Smith","number":"4111111111111111"}
    card_form = ::Io::Flow::V0::Models::CardForm.new(cc_hash)
    @card = FlowCommerce.instance.cards.post(ENV.fetch('FLOW_ORGANIZATION'), card_form)

    @card
  end

end