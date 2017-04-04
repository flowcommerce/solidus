# Flow.io (2017)
# adapter for Solidus/Spree that talks to activemerchant_flow

load '/Users/dux/dev/org/flow.io/activemerchant_flow/lib/active_merchant/billing/gateways/flow.rb'

module Spree
  class Gateway::Flow < Gateway
    def provider_class
      # ActiveMerchant::Billing::FlowGateway
      self.class
    end

    def actions
      %w(capture authorize purchase refund void)
    end

    # if user wants to force auto capture
    # def auto_capture?
    #   true
    # end

    def payment_profiles_supported?
      true
    end

    def create_profile(payment)
      # binding.pry
      # ActiveMerchant::Billing::FlowGateway.new(token: ENV.fetch('FLOW_API_KEY'), organization: ENV.fetch('FLOW_ORGANIZATION'))

      case payment.order.state
        when 'payment'
          # we have to save cc token
          # unless using credit card filter, payment.source.number
          # cc = payment.source
          # cc.flow_fetch_cc_token
          # cc.save
        when 'confirm'
          # payment.order.flow_cc_authorization
          # payment.order.flow_cc_capture if Spree::Config[:auto_capture]
      end
    end

    def supports?(source)
      # flow supports credit cards
      source.class == Spree::CreditCard
    end

    def authorize(amount, payment_method, options={})
      # fo.response['total']

      order = find_order options
      binding.pry
    end

    def capture(amount, payment_method, options={})
      binding.pry
    end

    def purchase(amount, payment_method, options={})
      binding.pry
    end

    def refund(money, authorization_key, options={})
      binding.pry
    end

    def void(money, authorization_key, options={})
      binding.pry
    end

    private

    def get_flow_order(options)
      order_number = options[:order_id].split('-').first
      spree_order  = Spree::Order.find_by(order_number: order_number)

      fo = FlowOrder.sync_from_spree_order order: spree_order, experience: FlowExperience.all.first
    end

  end
end