# Flow.io (2017)
# flow api helper

module Flow::Api
  extend self

  # adds cc and gets cc flow object
  # Flow::Api.credit_card(number:'4111111111111111', name:'Foo Bar', cvv:'123', expiration_year:2022, expiration_month:11)
  def credit_card credit_card
    cc_hash = case credit_card
      when Spree::CreditCard
        cc = {}
        cc[:number]           = credit_card.number
        cc[:name]             = credit_card.name
        cc[:cvv]              = credit_card.verification_value
        cc[:expiration_year]  = credit_card.year.to_i
        cc[:expiration_month] = credit_card.month.to_i
        cc
      when Hash
        credit_card
      else
        raise ArgumentError, 'Spree::CreditCard or Hash suported as credit card argument'
    end

    card_form = ::Io::Flow::V0::Models::CardForm.new(cc_hash)
    FlowCommerce.instance.cards.post(Flow.organization, card_form)
  end

end