# Flow.io (2017)
# communicates with flow payments api, easy access to session
# to basic shop frontend and backend needs

class Flow::SimpleGateway

  def initialize(order)
    @order = order
  end

  def cc_get_token
    cards = @order.credit_cards.select{ |cc| cc[:flow_cache]['cc_token'] }
    return unless cards.first
    cards.first.flow_cache['cc_token']
  end

  # authorises credit card and prepares for capture
  def cc_authorization
    cc_token = cc_get_token
    raise StandarError, 'Flow credit card token not found' unless cc_token

    flow_currency = @order.flow_order.total.currency
    flow_amount   = @order.flow_order.total.amount

    raise StandarError, 'Currency not found in flow cache' unless flow_currency
    raise StandarError, 'Amount not found in flow cache' unless flow_amount

    data = {
      'order_number':  @order.flow_number,
      'currency':      flow_currency,
      'amount':        flow_amount,
      'token':         cc_token,
    }

    # we allways have order id so we allways use MerchantOfRecordAuthorizationForm
    auth_form      = ::Io::Flow::V0::Models::MerchantOfRecordAuthorizationForm.new(data)
    response       = FlowCommerce.instance.authorizations.post(Flow.organization, auth_form)
    status_message = response.result.status.value
    status         = status_message == ::Io::Flow::V0::Models::AuthorizationStatus.authorized.value

    store = {
                  key: response.key,
                amount: response.amount,
              currency: response.currency,
      authorization_id: response.id
    }

    @order.update_column :flow_cache, @order.flow_cache.merge('authorization': store)

    ActiveMerchant::Billing::Response.new(status, status_message, { response: response }, { authorization: store })
  rescue Io::Flow::V0::HttpClient::ServerError => exception
    error_response(exception)
  end

  # capture authorised funds
  def cc_capture
    data = @order.flow_cache['authorization']

    raise ArgumentError, 'No Authorization data, please authorize first' unless data

    capture_form = ::Io::Flow::V0::Models::CaptureForm.new(data)
    response     = FlowCommerce.instance.captures.post(Flow.organization, capture_form)

    if response.id
      @order.update_column :flow_cache, @order.flow_cache.merge('capture': response.to_hash)
      @order.finalize!

      # @order.update_column :payment_state, 'completed'

      ActiveMerchant::Billing::Response.new true, 'success', { response: response }
    else
      ActiveMerchant::Billing::Response.new false, 'error', { response: response }
    end
  rescue => exception
    error_response(exception)
  end

  def cc_refund
    raise ArgumentError, 'capture info is not available' unless @order.flow_cache['capture']

    # we allways have capture ID, so we use it
    refund_data = { capture_id: @order.flow_cache['capture']['id'] }
    refund_form = ::Io::Flow::V0::Models::RefundForm.new(refund_data)
    response    = FlowCommerce.instance.refunds.post(Flow.organization, refund_form)

    if response.id
      @order.update_column :flow_cache, @order.flow_cache.merge('refund': response.to_hash)
      ActiveMerchant::Billing::Response.new true, 'success', { response: response }
    else
      ActiveMerchant::Billing::Response.new false, 'error', { response: response }
    end
  rescue => exception
    error_response(exception)
  end

  private

  # we want to return errors in standardized format
  def error_response(exception_object, message=nil)
    message = if exception_object.respond_to?(:body) && exception_object.body.length > 0
      description  = JSON.load(exception_object.body)['messages'].to_sentence
      '%s: %s (%s)' % [exception_object.details, description, exception_object.code]
    else
      exception_object.message
    end

    ActiveMerchant::Billing::Response.new(false, message, exception: exception_object)
  end
end

