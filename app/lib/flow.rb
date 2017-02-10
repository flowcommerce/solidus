# module for communication and customization based on flow api
# for now all in same class

module Flow
  extend self

  EXPERIENCES_PATH = './config/flow_experiences.yml'
  raise StandardError, 'Experiences yaml not found in %s' % yml_pathEXPERIENCES_PATH unless File.exists?(EXPERIENCES_PATH)

  # precache expirinces in thread memory
  EXPERIENCES = YAML.load_file(EXPERIENCES_PATH).map { |el|
    hash = ActiveSupport::HashWithIndifferentAccess.new(el)
    hash.freeze
  }

  # builds curl command and gets remote data
  def api(action, path, params={})
    body  = params.delete(:BODY)

    remote_params = URI.encode_www_form params
    remote_path   = path.sub('%o', ENV.fetch('FLOW_ORG')).sub(':organization', ENV.fetch('FLOW_ORG'))
    remote_path  += '?%s' % remote_params unless remote_params.blank?

    curl = ['curl -s']
    curl.push '-X %s' % action.to_s.upcase
    curl.push '-u %s:' % ENV.fetch('FLOW_API_KEY')
    if body
      curl.push '-H "Content-Type: application/json"'
      curl.push "-d '%s'" % body.gsub(%['], %['"'"']) if body
    end
    curl.push '"https://api.flow.io%s"' % remote_path
    command = curl.join(' ')

    puts command

    data = JSON.load `#{command}`

    if data.kind_of?(Hash) && data['code'] == 'generic_error'
      ap data
      data
    else
      data
    end
  end

  ###

  # gets localy cached expiriences
  # prebuild cache with "rake flow:get_experiences"
  # "https://flowcdn.io/util/icons/flags/32/%s.png" % el['region']['id']
  def experiences
    EXPERIENCES
  end

  def experience(key)
    EXPERIENCES.each do |exp|
      return exp if exp['region']['id'] == key
    end
    nil
  end

  # get only local country codes
  def country_codes
    Flow::EXPERIENCES.map{ |el| el['country'].downcase }
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
