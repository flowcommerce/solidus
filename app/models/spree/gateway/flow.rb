module Spree
  class Gateway::Flow < Gateway
    preference :currency, :string, :default => 'USD'


    # def provider_class
    #   ActiveMerchant::Billing::FlowGateway
    # end
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