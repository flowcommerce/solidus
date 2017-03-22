module Spree
  class Gateway::Flow < Gateway::Bogus
    preference :currency, :string, :default => 'USD'


    # def provider_class
    #   ActiveMerchant::Billing::FlowGateway
    # end

    def provider_class
      self.class
    end

    def payment_profiles_supported?
      false
    end

    def create_profile(payment)
      raise payment

      return if payment.source.has_payment_profile?
      # simulate the storage of credit card profile using remote service
      if success = VALID_CCS.include?(payment.source.number)
        payment.source.update_attributes(gateway_customer_profile_id: generate_profile_id(success))
      end
    end

    def capture(_money, authorization, _gateway_options)
      raise 123
      if authorization == '12345'
        ActiveMerchant::Billing::Response.new(true, 'Bogus Gateway: Forced success', {}, test: true)
      else
        ActiveMerchant::Billing::Response.new(false, 'Bogus Gateway: Forced failure', error: 'Bogus Gateway: Forced failure', test: true)
      end
    end

    def authorize(amount, payment_method, options={})
      raise 12345
      Response.new(true, 'force authorize')
    end

    def purchase(amount, payment_method, options={})
      raise 12345
      Response.new(true, 'force purchase')
    end
  end
end