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

    @orders = Spree::Order.order('id desc').page(params[:page]).per(20)
  end

  private

  def user_is_admin
    return true if spree_current_user && spree_current_user.admin?
    render text: 'You must be admin to access flow admin'
    false
  end

end