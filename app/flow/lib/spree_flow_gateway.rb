# Flow.io (2017)
# adapter for Solidus/Spree that talks to activemerchant_flow

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
      true
    end

    def method_type
      'gateway'
    end

    def preferences
      {}
    end

    def supports? source
      # flow supports credit cards
      source.class == Spree::CreditCard
    end

    def authorize amount, payment_method, options={}
      order = load_order options
      order.cc_authorization
    end

    def capture amount, payment_method, options={}
      order = load_order options
      order.cc_capture
    end

    def purchase amount, payment_method, options={}
      order = load_order options
      flow_auth = order.cc_authorization

      if flow_auth.success?
        order.cc_capture
      else
        flow_auth
      end
    end

    def refund money, authorization_key, options={}
      order = load_order options
      order.cc_refund
    end

    def void money, authorization_key, options={}
      # binding.pry
    end

    def create_profile payment
      # binding.pry

      # payment.order.state
      @credit_card = payment.source

      profile_ensure_payment_method_is_present!
      create_flow_cc_profile!
    end

    private

    # hard inject Flow as payment method unless defined
    def profile_ensure_payment_method_is_present!
      return if @credit_card.payment_method_id

      flow_payment = Spree::PaymentMethod.where(active: true, type:'Spree::Gateway::Flow').first
      @credit_card.payment_method_id = flow_payment.id if flow_payment
    end

    # create payment profile with Flow and tokenize Credit Card
    def create_flow_cc_profile!
      return if @credit_card.gateway_customer_profile_id
      return unless @credit_card.verification_value

      # build credit card hash
      data = {}
      data[:number]           = @credit_card.number
      data[:name]             = @credit_card.name
      data[:cvv]              = @credit_card.verification_value
      data[:expiration_year]  = @credit_card.year.to_i
      data[:expiration_month] = @credit_card.month.to_i

      # tokenize with Flow
      # rescue Io::Flow::V0::HttpClient::ServerError
      card_form = ::Io::Flow::V0::Models::CardForm.new(data)
      result    = FlowCommerce.instance.cards.post(::Flow.organization, card_form)

      @credit_card.update_column :gateway_customer_profile_id, result.token
    end

    def load_order options
      order_number = options[:order_id].split('-').first
      spree_order  = Spree::Order.find_by number: order_number
      ::Flow::SimpleGateway.new spree_order
    end
  end
end