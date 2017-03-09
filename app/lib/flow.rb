# module for communication and customization based on flow api
# for now all in same class

module Flow
  extend self

  # this method is not a constant so it can be replaced
  def price_not_found
    'n/a'
  end

  # builds curl command and gets remote data
  def api(action, path, params={})
    body  = params.delete(:BODY)

    remote_params = URI.encode_www_form params
    remote_path   = path.sub('%o', ENV.fetch('FLOW_ORG')).sub(':organization', ENV.fetch('FLOW_ORG'))
    remote_path  += '?%s' % remote_params unless remote_params.blank?

    curl = ['curl -s']
    curl.push '-X %s' % action.to_s.upcase
    curl.push '-u %s:' % ENV.fetch('FLOW_TOKEN')
    if body
      body = body.to_json unless body.is_a?(Array)
      curl.push '-H "Content-Type: application/json"'
      curl.push "-d '%s'" % body.gsub(%['], %['"'"']) if body
    end
    curl.push '"https://api.flow.io%s"' % remote_path
    command = curl.join(' ')

    data = JSON.load `#{command}`

    if data.kind_of?(Hash) && data['code'] == 'generic_error'
      ap data
      data
    else
      data
    end
  end

end
