module Spree
  class Gateway::Flow < Gateway
    preference :currency, :string, :default => 'USD'

    def provider_class
      ActiveMerchant::Billing::FlowGateway
    end

    def actions
      %w(capture authorize refund void)
    end

    def payment_profiles_supported?
      false
    end

    def supports?(source)
      # flow supports credit cards
      source.class == Spree::CreditCard
    end

    # creates profile for credit card on flow
    def create_profile(payment)
      # but we need cc number which we do not get here
      # se we are using before_save filter on credit card
      # to allways create profile on flow for every cc

      return true

      # if we had number on credit card, we could enable this code

      # credit_card = payment.order.credit_cards.first
      # return unless credit_card

      # if credit_card.flow_fetch_cc_token
      #   credit_card.save!
      # end
    end

  end
end