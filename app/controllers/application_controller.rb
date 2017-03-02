class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :check_and_set_flow_experience
  after_action :maintain_flow_order

  private

  # checks current experience (defiend by parameter) and sets default one unless one preset
  def check_and_set_flow_experience
    if exp = params[:exp]
      session[:flow_exp] = exp.downcase if Flow.country_codes.include?(exp.upcase)
      return redirect_to request.path
    end

    # ensure we have the right experince in session
    session.delete(:flow_exp) unless Flow.country_codes.include?(session[:flow_exp].to_s.upcase)

    # set session exp unless set
    session[:flow_exp] ||= Flow.get_experience_for_ip(request.ip)[:country].downcase rescue Flow.country_codes.first.downcase
    flow_exp = Flow.experience(session[:flow_exp]) || Flow.experiences.first
    @flow_exp = Hashie::Mash.new(flow_exp).freeze
  end

  def maintain_flow_order
    target = '%s#%s' % [params[:controller], params[:action]]

    # if @order # alternative way
    # implement order cacheing via session check
    if [
      'spree/checkout#edit',
      'spree/orders#edit'
    ].include?(target)
      address = @current_spree_user ? @current_spree_user.addresses.first : nil

      FlowOrder.sync_from_spree_order(experience: @flow_exp, order: @order, address: address)
    end
  end
end
