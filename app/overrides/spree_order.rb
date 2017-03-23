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
    data = {
      'discriminator': 'merchant_of_record_authorization_form',
      'order_number':  flow_number,
      'currency':      currency,
      'amount':        total,
      'token':         flow_cc_token,
    }
    # response = FlowRoot.api(:post, '/:organization/authorizations', BODY: data
    auth_form = ::Io::Flow::V0::Models::DirectAuthorizationForm.new(data)
    response  = FlowCommerce.instance.authorizations.post(ENV.fetch('FLOW_ORG'), auth_form)

    if response.result.status.value == 'authorized'
      # what store this in spree order object, for capure
      store = {}
      store['authorization_id'] = response.id
      store['currency']         = response.currency
      store['amount']           = response.amount
      store['key']              = response.key
      update_column :flow_cache, flow_cache.merge('authorization': store)
    end

    response.to_hash
  end

  # capture authorised funds
  def flow_cc_capture
    data = flow_cache['authorization']

    raise ArgumentError, 'No Authorization data, please authorize first' unless data

    # response     = FlowRoot.api :post, '/:organization/captures', BODY: data
    capture_form = ::Io::Flow::V0::Models::CaptureForm.new(data)
    response     = FlowCommerce.instance.captures.post(ENV.fetch('FLOW_ORG'), capture_form)
    body         = response.to_hash

    update_column :flow_cache, flow_cache.merge('capture': body)

    body
  end

end

