# flow specific controller

class FlowController < ApplicationController
  layout 'flow'
  skip_before_filter :verify_authenticity_token, only: :handle_flow_web_hook_event

  # forward all incoming requests to Flow Webhook service object
  # /flow/event-target
  def handle_flow_web_hook_event
    data     = JSON.parse request.body.read
    response = Flow::Webhook.process data
    render text: response
  rescue ArgumentError => e
    render text: e.message, status: 400
  end

  def index
    # solidus method
    return unless user_is_admin

    if action = params[:flow]
      order = Spree::Order.find(params[:o_id])

      case action
        when 'order'
          # response = FlowCommerce.instance.orders.get_by_number(Flow.organization, order.flow_number)
          response = Flow.api(:get, '/:organization/orders/%s' % order.flow_number)
        when 'raw'
          response = order.attributes
        when 'auth'
          flow_response = order.flow_cc_authorization
          response      = flow_response.success? ? flow_response.params['response'].to_hash : flow_response.message
        when 'capture'
          flow_response = order.flow_cc_capture
          response      = flow_response.success? ? flow_response.params['response'].to_hash : flow_response.message
        when 'refund'
          response = order.flow_cache['refund']

          unless response
            flow_response = order.flow_cc_refund
            response = flow_response.success? ? order.flow_cache['refund'] : flow_response.message
          end
        else
          return render text: 'Ation %s not supported' % action
      end

      render json: response
    else
      @orders = Spree::Order.order('id desc').page(params[:page]).per(20)
    end
  rescue
    render text: '%s: %s' % [$!.class.to_s, $!.message]
  end

  def about
  end

  def restrictions
    @list = {}
  end

  private

  def user_is_admin
    return true if spree_current_user && spree_current_user.admin?
    render text: 'You must be admin to access flow admin'
    false
  end

end