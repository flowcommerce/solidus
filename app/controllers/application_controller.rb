class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_filter :check_and_set_flow_experience

  private

  # checks current experience (defiend by subdomain) and sets default one unless one preset
  def check_and_set_flow_experience
    # get only expirience keys
    experiences = Flow.experiences.map{ |el| el[:region][:id] }

    # redirect to first expirience unless one defined is found
    unless experiences.include?(request.subdomain)
      domain = request.domain == 'localhost' ? 'lvh.me' : request.domain

      redirect_to '%s://%s.%s:%s%s' % [request.url.split(':').first, experiences.first, domain, request.port, request.path]
    end
  end
end
