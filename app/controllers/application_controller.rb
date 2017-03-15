class ApplicationController < ActionController::Base
  FLOW_SESSION_KEY = :_f60_session

  protect_from_forgery    with: :exception
  before_action           :flow_check_and_set_country, :flow_update_selection

  # before render trigger
  # rails does not have before_render filter so we create it like this
  # to make things simple
  def render(*args)
    # call method if one defined
    target        = '%s#%s' % [params[:controller], params[:action]]
    filter_method = ('flow_filter_' + target.gsub!(/[^\w]/,'_')).to_sym
    send(filter_method) if self.class.private_instance_methods.include?(filter_method)

    # call all this methods
    sync_flow_order

    # return our data or call super render
    @flow_render ? super(@flow_render) : super
  end

  private

  # If we have a flow session, return an instance of Io::Flow::V0::Models::Session
  def set_flow_session(experience=nil)
    value = cookies.permanent[FLOW_SESSION_KEY]

    @flow_session = if value.present?
      FlowSession.new hash: JSON.load(value)
    else
      session = FlowSession.new ip: request.ip, experience: experience
      cookies.permanent[FLOW_SESSION_KEY] = session.to_json
      session
    end
    @flow_exp = @flow_session.local.experience
  end

  # checks current experience (defined by parameter) and sets default one unless one preset
  def flow_check_and_set_country
    set_flow_session

    if flow_exp_key = params[:flow_exp]
      @flow_session.change_experience(flow_exp_key)
      cookies.permanent[FLOW_SESSION_KEY] = @flow_session.to_json
      redirect_to request.path
    end
  end

  ###

  # update selection (delivery options) on /checkout/update/delivery
  def flow_update_selection
    if params[:flow_order_id] && params[:flow_selection]
      # empty array is nil, so we allways send placeholder
      params[:flow_selection].delete('placeholder')

      order_id = Flow::Crypt.decrypt(params[:flow_order_id])
      order = Spree::Order.find(order_id)
      order.update_column :flow_cache, order.flow_cache.merge('selection'=>params[:flow_selection])
    end
  end

  # we need to prepare @order and sync to flow.io before render because we need
  # flow total price
  def sync_flow_order
    return unless @order

    @flow_order = FlowOrder.sync_from_spree_order(experience: @flow_exp, order: @order, customer: @current_spree_user)
    @flow_render = { json: JSON.pretty_generate(@flow_order.response) } if params[:debug] == 'flow'
  end

  def flow_filter_spree_products_show
    # r @product.variants.first.flow_cache
    @flow_render = { json: JSON.pretty_generate(@flow_exp.get_item(@product).to_hash) } if params[:debug] == 'flow'
    # @product.variants.first.update_column :flow_cache, nil
  end

  def flow_filter_spree_checkout_edit
    # r @flow_order.deliveries
  end

end
