# module for communication and customization based on flow api
# for now all in same class

require 'logger'

module FlowRoot
  extend self

  # builds curl command and gets remote data
  def api(action, path, params={})
    body  = params.delete(:BODY)

    remote_params = URI.encode_www_form params
    remote_path   = path.sub('%o', ENV.fetch('FLOW_ORGANIZATION')).sub(':organization', ENV.fetch('FLOW_ORGANIZATION'))
    remote_path  += '?%s' % remote_params unless remote_params.blank?

    curl = ['curl -s']
    curl.push '-X %s' % action.to_s.upcase
    curl.push '-u %s:' % ENV.fetch('FLOW_API_KEY')
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

  # for debugging
  def get_item(flow_exp, number)
    # FlowCommerce.instance.experiences.get_items_and_price_by_key_and_number(FLOW_ORG, flow_exp, '100')
    # api :get, ''
  end

  def logger
    @logger ||= Logger.new('./log/flow.log') # or nil for no logging
  end

end
