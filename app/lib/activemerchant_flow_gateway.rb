# https://github.com/glossier/solidus_retail/blob/master/lib/active_merchant/billing/gateways/shopify.rb

module ActiveMerchant
  module Billing
    class FlowGateway < Gateway
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
end