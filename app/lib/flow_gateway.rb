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

    # def create_profile(payment)
    #   raise payment

    #   return if payment.source.has_payment_profile?
    #   # simulate the storage of credit card profile using remote service
    #   if success = VALID_CCS.include?(payment.source.number)
    #     payment.source.update_attributes(gateway_customer_profile_id: generate_profile_id(success))
    #   end
    # end

    def capture(_money, authorization, _gateway_options)
      raise 'flow:capture'
      if authorization == '12345'
        ActiveMerchant::Billing::Response.new(true, 'Bogus Gateway: Forced success', {}, test: true)
      else
        ActiveMerchant::Billing::Response.new(false, 'Bogus Gateway: Forced failure', error: 'Bogus Gateway: Forced failure', test: true)
      end
    end

    def authorize(amount, payment_method, options={})
      # ap [amount, payment_method, options]; raise 'flow:authorize'

      # load order
      order_number = options[:order_id].split('-').first
      order = Spree::Order.find_by number: order_number

      # try to authorise and get response
      response = order.flow_cc_authorization
      # binding.pry
      ActiveMerchant::Billing::Response.new(response.result.status.value == 'authorized', 'Flow authorize')
    end

    def purchase(amount, payment_method, options={})
      raise 'flow:purchase'
      ActiveMerchant::Billing::Response.new(true, 'force purchase')
    end
  end
end