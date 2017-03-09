class ApplicationController < ActionController::Base
  protect_from_forgery    with: :exception
  before_action           :check_and_set_flow_experience

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

  # checks current experience (defiend by parameter) and sets default one unless one preset
  def check_and_set_flow_experience
    if exp = params[:exp]
      session[:flow_exp_key] = exp if FlowExperience.keys.include?(exp)
      return redirect_to request.path
    end

    # set session exp unless set
    session[:flow_exp_key] ||= FlowExperience.key_by_ip(request.ip)
    @flow_exp = FlowExperience.init_by_key(session[:flow_exp_key]) || Flow.experiences.first
  end

  ###

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
end
