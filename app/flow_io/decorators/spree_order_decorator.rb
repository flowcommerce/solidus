# added flow specific methods to Spree::Order
# http://docs.solidus.io/Spree/Order.html

require 'digest/sha1'

Spree::Order.class_eval do

  # we now use Solidus number as Flow number, but I will this here for now
  def flow_number
    return self[:flow_number] unless self[:flow_number].blank?
    return unless id
    number
  end

  # shows localized total, if possible. if not, fall back to Solidus default
  def flow_total
    experience_key = flow_cache['experience_key']
    cache_total    = flow_cache['total']
    total          = nil

    if cache_total
      total = cache_total[experience_key]

      if cache_total['current'].is_a?(Hash)
        total ||= '%s %s' % [cache_total['current']['amount'], cache_total['current']['currency']]
      end
    end

    total && total =~ /\d/ ? total : '%s %s' % [self.total, currency]
  end

  def flow_cc_token
    cards = credit_cards.select{ |cc| cc[:flow_cache]['cc_token'] }
    return unless cards.first
    cards.first.flow_cache['cc_token']
  end

  # authorises credit card and prepares for capture
  def flow_cc_authorization
    raise StandarError, 'Flow credit card token not found' unless flow_number

    flow_currency = flow_cache['total']['current']['currency']
    flow_amount   = flow_cache['total']['current']['amount']

    raise StandarError, 'Currency not found in flow cache' unless flow_currency
    raise StandarError, 'Amount not found in flow cache' unless flow_amount

    data = {
      'order_number':  flow_number,
      'currency':      flow_currency,
      'amount':        flow_amount,
      'token':         flow_cc_token,
    }

    # we allways have order id so we allways use MerchantOfRecordAuthorizationForm
    auth_form      = ::Io::Flow::V0::Models::MerchantOfRecordAuthorizationForm.new(data)
    response       = FlowCommerce.instance.authorizations.post(Flow.organization, auth_form)
    status_message = response.result.status.value
    status         = status_message == ::Io::Flow::V0::Models::AuthorizationStatus.authorized.value

    store = {}
    store['authorization_id'] = response.id
    store['currency']         = response.currency
    store['amount']           = response.amount
    store['key']              = response.key

    update_column :flow_cache, flow_cache.merge('authorization': store)

    ActiveMerchant::Billing::Response.new(status, status_message, {response: response}, {authorization: store})
  rescue Io::Flow::V0::HttpClient::ServerError => exception
    flow_error_response(exception)
  end

  # capture authorised funds
  def flow_cc_capture
    data = flow_cache['authorization']

    raise ArgumentError, 'No Authorization data, please authorize first' unless data

    capture_form = ::Io::Flow::V0::Models::CaptureForm.new(data)
    response     = FlowCommerce.instance.captures.post(Flow.organization, capture_form)

    if response.id
      update_column :flow_cache, flow_cache.merge('capture': response.to_hash)
      finalize!

      # update_column :payment_state, 'completed'

      ActiveMerchant::Billing::Response.new(true, 'success', {response: response})
    else
      ActiveMerchant::Billing::Response.new(false, 'error', {response: response})
    end
  rescue => exception
    flow_error_response(exception)
  end

  def flow_cc_refund
    raise ArgumentError, 'capture info is not available' unless flow_cache['capture']

    # we allways have capture ID, so we use it
    refund_data = { capture_id: flow_cache['capture']['id'] }
    refund_form = ::Io::Flow::V0::Models::RefundForm.new(refund_data)
    response    = FlowCommerce.instance.refunds.post(Flow.organization, refund_form)

    if response.id
      update_column :flow_cache, flow_cache.merge('refund': response.to_hash)
      ActiveMerchant::Billing::Response.new(true, 'success', {response: response})
    else
      ActiveMerchant::Billing::Response.new(false, 'error', {response: response})
    end
  rescue => exception
    flow_error_response(exception)
  end

  # clear invalid zero amount payments. Solidsus bug?
  def clear_zero_amount_payments!
    # class attribute that can be set to true
    return unless Flow::Order.clear_zero_amount_payments

    payments.where(amount:0, state: 'invalid').map(&:destroy)
  end

  private

  # we want to return errors in standardized format
  def flow_error_response(exception_object, message=nil)
    message = if exception_object.respond_to?(:body) && exception_object.body.length > 0
      description  = JSON.load(exception_object.body)['messages'].to_sentence
      '%s: %s (%s)' % [exception_object.details, description, exception_object.code]
    else
      exception_object.message
    end

    ActiveMerchant::Billing::Response.new(false, message, exception: exception_object)
  end
end

