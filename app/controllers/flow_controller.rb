# flow specific controller

class FlowController < ApplicationController

  layout 'flow'

  # when products are updated in Flow catalog, event is trigered
  # this hook can capture all events and update products in catalog
  def handle_flow_web_hook_event
    render text: 'ok'
  end

  def order_update
    render text: 'ok'
  end

  def index
    return unless user_is_admin

    if action = params[:flow]
      order = Spree::Order.find(params[:o_id])

      case action
        when 'order'
          # response = FlowCommerce.instance.orders.get_by_number(ENV.fetch('FLOW_ORGANIZATION'), order.flow_number)
          response = FlowRoot.api(:get, '/:organization/orders/%s' % order.flow_number)
        when 'raw'
          response = order.attributes
        when 'auth'
          response = order.flow_cc_authorization.to_hash
        when 'capture'
          response = order.flow_cc_capture.to_hash
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

  private

  def user_is_admin
    return true if spree_current_user && spree_current_user.admin?
    render text: 'You must be admin to access flow admin'
    false
  end

end