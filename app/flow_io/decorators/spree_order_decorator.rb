# added flow specific methods to Spree::Order
# http://docs.solidus.io/Spree/Order.html

require 'digest/sha1'

Spree::Order.class_eval do

  # defines uniqe flow number per order
  # format "solidus-order-hash" -> "s-o-hash"
  def flow_number
    return self[:flow_number] unless self[:flow_number].blank?
    return unless id

    token = ENV.fetch('SECRET_TOKEN')
    number = 's-o-%s' % Digest::SHA1.hexdigest('%d-%s' % [id, token])

    # fast update without callbacks
    update_column :flow_number, number

    number
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
    auth_form = ::Io::Flow::V0::Models::MerchantOfRecordAuthorizationForm.new(data)
    response  = FlowCommerce.instance.authorizations.post(Flow.organization, auth_form)

    # binding.pry
    # if response.authorized
    if response.result.status.value == 'authorized'
      # what store this in spree order object, for capure
      store = {}
      store['authorization_id'] = response.id
      store['currency']         = response.currency
      store['amount']           = response.amount
      store['key']              = response.key

      update_column :flow_cache, flow_cache.merge('authorization': store)
    end

    ActiveMerchant::Billing::Response.new(true, 'success', {response: response}, {authorization: store})
  rescue Io::Flow::V0::HttpClient::ServerError => exception
    flow_error_response(exception)
  end

  # capture authorised funds
  def flow_cc_capture
    data = flow_cache['authorization']

    raise ArgumentError, 'No Authorization data, please authorize first' unless data

    capture_form = ::Io::Flow::V0::Models::CaptureForm.new(data)
    response     = FlowCommerce.instance.captures.post(ENV.fetch('FLOW_ORGANIZATION'), capture_form)

    if response.id
      update_column :flow_cache, flow_cache.merge('capture': response.to_hash)
      finalize!
    end

    ActiveMerchant::Billing::Response.new(true, 'success', {response: response})
  rescue => exception
    flow_error_response(exception)
  end

  private

  # we want to return errors in standardized format
  def flow_error_response(exception_object, message=nil)
    message ||= exception_object.message
    ActiveMerchant::Billing::Response.new(false, message, exception: exception_object)
  end
end

