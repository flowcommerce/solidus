class ApplicationController < ActionController::Base
  protect_from_forgery    with: :exception
  before_action           :check_and_set_flow_experience

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

  # we need to prepare @order and sync to flow.io before render because we need
  # flow total price
  def sync_flow_order
    # target = '%s#%s' % [params[:controller], params[:action]]
    # if ['spree/checkout#edit','spree/orders#edit'].include?(target)

    # ap @product.variants.first.flow_cache

    # r @flow_exp.get_item @product

    # @product.variants.first.update_column :flow_cache, nil


    return unless @order

    FlowOrder.sync_from_spree_order(experience: @flow_exp, order: @order, customer: @current_spree_user)
  end

  # before render trigger
  # rails does not have before_render filter so we create it like this
  # to make things simple
  def render(*args)
    [:sync_flow_order].each { |action| send action }
    super
  end
end
