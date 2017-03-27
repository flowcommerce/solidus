module ActiveMerchant
  module Billing
    class FlowGateway < Gateway

      self.display_name     = 'Flow.io Pay'
      self.homepage_url     = 'https://www.flow.io/'
      self.default_currency = 'USD'

      def authorize(amount, payment_method, options={})
        # load order
        order = get_spree_order options

        # try to authorise and get response
        response = order.flow_cc_authorization

        Response.new(response.result.status.value == 'authorized', 'Flow authorize - Success')
      end

      def capture(_money, authorization, options={})
        # load order
        order = get_spree_order options

        # try to capture funds
        order.flow_cc_capture

        ActiveMerchant::Billing::Response.new(true, 'Flow Gateway - Success')
      rescue => ex
        ActiveMerchant::Billing::Response.new(false, ex.message)
      end

      def refund(money, authorization, options={})
        # to do
        ActiveMerchant::Billing::Response.new(true, 'Flow Gateway - Success')
      end

      def void(money, authorization, options={})
        # to do
        ActiveMerchant::Billing::Response.new(true, 'Flow Gateway - Success')
      end

      private

      def get_spree_order(options)
        order_number = options[:order_id].split('-').first

        Spree::Order.find_by number: order_number
      end

    end
  end
end