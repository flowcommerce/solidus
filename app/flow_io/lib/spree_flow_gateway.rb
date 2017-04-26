# Flow.io (2017)
# adapter for Solidus/Spree that talks to activemerchant_flow

# load '/Users/dux/dev/org/flow.io/activemerchant_flow/lib/active_merchant/billing/gateways/flow.rb'

module Spree
  class Gateway::Flow < Gateway
    def provider_class
      self.class
    end

    def actions
      %w(capture authorize purchase refund void)
    end

    # if user wants to force auto capture
    def auto_capture?
      false
    end

    def payment_profiles_supported?
      false
    end

    def preferences
      {}
    end

    # def create_profile(payment)
    #   # binding.pry
    #   # ActiveMerchant::Billing::FlowGateway.new(token: Flow.api_key, organization: Flow.organization)

    #   case payment.order.state
    #     when 'payment'
    #     when 'confirm'
    #   end
    # end

    def supports?(source)
      # flow supports credit cards
      source.class == Spree::CreditCard
    end

    def authorize(amount, payment_method, options={})
      order = get_spree_order options
      order.clear_zero_amount_payments!
      order.flow_cc_authorization
    end

    def capture(amount, payment_method, options={})
      order = get_spree_order options
      order.flow_cc_capture
    end

    def purchase(amount, payment_method, options={})
      order = get_spree_order options
      flow_auth = order.flow_cc_authorization

      if flow_auth.success?
        order.flow_cc_capture
      else
        flow_auth
      end
    end

    def refund(money, authorization_key, options={})
      order = get_spree_order options
      order.clear_zero_amount_payments!
      order.flow_cc_refund
    end

    def void(money, authorization_key, options={})
      # binding.pry
    end

    private

    def get_spree_order(options)
      order_number = options[:order_id].split('-').first

      Spree::Order.find_by(number: order_number)
    end
  end
end