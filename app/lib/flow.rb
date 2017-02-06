module Flow
  extend self

  # builds curl command and gets remote data
  def remote(action, path, params={})
    remote_params = URI.encode_www_form params
    remote_path   = path.sub('%o', ENV.fetch('FLOW_ORG')).sub(':organization', ENV.fetch('FLOW_ORG'))
    remote_path   += '?%s' % remote_params if remote_params

    command = 'curl -s -X %s -u %s: https://api.flow.io%s' % [action.to_s.upcase, ENV.fetch('FLOW_API_KEY'), remote_path]
    JSON.load `#{command}`
  end

  ###

  def experiences
    yml_path = './config/flow_experiences.yml'

    raise StandardError, 'Experiences yaml not found in %s' % yml_path unless File.exists?(yml_path)

    list = YAML.load_file yml_path

    # return hash that we can access with
    list.map { |el|
      hash = ActiveSupport::HashWithIndifferentAccess.new(el)
      hash[:flag] = "https://flowcdn.io/util/icons/flags/32/#{el['region']['id']}.png"
      hash
    }
  end

  def geolocaton(ip)
    data = remote :get, '/geolocation/defaults'
    data.first
  end

end