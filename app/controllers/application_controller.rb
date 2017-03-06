class ApplicationController < ActionController::Base
  protect_from_forgery    with: :exception
  before_action           :check_and_set_flow_experience

  private

  # checks current experience (defiend by parameter) and sets default one unless one preset
  def check_and_set_flow_experience
    # r FlowCommerce::Models::V0::OrganizationSessionForm( organization: ENV.fetch('FLOW_ORG'), ip: request.ip)

    if exp = params[:exp]
      session[:flow_exp] = exp.downcase if Flow.country_codes.include?(exp.upcase)
      return redirect_to request.path
    end

    # ensure we have the right experince in session
    session.delete(:flow_exp) unless Flow.country_codes.include?(session[:flow_exp].to_s.upcase)

    # set session exp unless set
    session[:flow_exp] ||= Flow.get_experience_for_ip(request.ip)[:country].downcase rescue Flow.country_codes.first.downcase
    flow_exp = Flow.experience(session[:flow_exp]) || Flow.experiences.first

    flow_exp['IP'] = request.ip

    @flow_exp = Hashie::Mash.new(flow_exp).freeze
  end

  # we need to prepare @order and sync to flow.io before render because we need
  # flow total price
  def sync_flow_order
    # target = '%s#%s' % [params[:controller], params[:action]]
    # if ['spree/checkout#edit','spree/orders#edit'].include?(target)

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
