# module for communication and customization based on flow api
# for now all in same class

module Flow
  extend self

  EXPERIENCES_PATH = './config/flow_experiences.yml'
  raise StandardError, 'Experiences yaml not found in %s' % yml_pathEXPERIENCES_PATH unless File.exists?(EXPERIENCES_PATH)

  # precache expirinces in thread memory
  EXPERIENCES = YAML.load_file(EXPERIENCES_PATH).map { |el|
    hash = ActiveSupport::HashWithIndifferentAccess.new(el)
    hash
  }

  # builds curl command and gets remote data
  def remote(action, path, params={})
    remote_params = URI.encode_www_form params
    remote_path   = path.sub('%o', ENV.fetch('FLOW_ORG')).sub(':organization', ENV.fetch('FLOW_ORG'))
    remote_path  += '?%s' % remote_params if remote_params

    command = 'curl -s -X %s -u %s: https://api.flow.io%s' % [action.to_s.upcase, ENV.fetch('FLOW_API_KEY'), remote_path]
    JSON.load `#{command}`
  end

  ###

  # gets localy cached expiriences
  # prebuild cache with "rake flow:get_experiences"
  # "https://flowcdn.io/util/icons/flags/32/%s.png" % el['region']['id']
  def experiences
    EXPERIENCES
  end

  # gets current expirence from request
  def current_expirience(request)
    current = request.subdomain

    EXPERIENCES.each do |el|
      return el if el['region']['id'] == current
    end
  end

  def get_experience_url(request, exp_key)
    '%s://%s.%s:%s%s' % [request.url.split(':').first, exp_key, request.domain, request.port, request.path]
  end

  # get country defaults
  # https://docs.flow.io/#/module/geolocation
  def country_defaults(ip)
    data = remote :get, '/geolocation/defaults', ip: ip
    data.first
  end

end
