Spree::OrderMailer.class_eval do

  def refund_complete_email web_hook_event
    # web_hook_event ||= JSON.load File.read('./tmp/refunds.json')
    auth_id          = web_hook_event.dig('refund_capture', 'refund', 'authorization', 'key')

    raise Flow::Error.new('authorization key not found in WebHookEvent [refund_capture_upserted_v2]') unless auth_id

    # authorization    = Flow.api :get, '/:organization/authorizations/%s' % auth_id
    authorization = FlowCommerce.instance.authorizations.get_by_key Flow.organization, auth_id

    @full_name = '%s %s' % [authorization.customer.name.first, authorization.customer.name.last]
    @amount    = '%s %s' % [authorization.requested.amount, authorization.requested.currency]
    @mail_to   = authorization.customer.email

    mail ({to: @mail_to, subject: 'We refunded your order for %s' % @amount})
  end

end