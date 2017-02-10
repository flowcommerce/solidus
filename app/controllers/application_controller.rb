class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :check_and_set_flow_experience

  private

  # checks current experience (defiend by parameter) and sets default one unless one preset
  def check_and_set_flow_experience
    if exp = params[:exp]
      session[:flow_exp] = exp if Flow.country_codes.include?(exp)
      return redirect_to request.path
    end

    flow_key = session[:flow_exp] || Flow.country_codes.first
    flow_exp = Flow.experience(flow_key) || Flow.experiences.first
    @flow_exp = Hashie::Mash.new(flow_exp).freeze
  end
end
