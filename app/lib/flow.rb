# module for communication and customization based on flow api
# for now all in same class

module Flow
  extend self

  EXPERIENCES_PATH = './config/flow_experiences.yml'
  raise StandardError, 'Experiences yaml not found in %s' % EXPERIENCES_PATH unless File.exists?(EXPERIENCES_PATH)

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
    curl.push '-u %s:' % ENV.fetch('FLOW_TOKEN')
    if body
      url.push '-H "Content-Type: application/json"'
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

  # format price given amount and currency
  def format_price(price, currency)
    # we can send experience object as well
    currency = currency.currency if currency.respond_to?(:currency)
    currency = currency.upcase

    # use rails helper
    amount = ActionController::Base.helpers.number_with_delimiter(price)

    # when USD, format in this special way
    if currency == 'USD'
      '$ %s' % amount
    else
      '%s %s' % [amount, currency]
    end
  end

  # get country defaults
  # https://docs.flow.io/#/module/geolocation
  def country_defaults(ip)
    data = remote :get, '/geolocation/defaults', ip: ip
    data.first
  end

  # fetch price from flow cache and render it
  def render_price_from_flow(exp, product)
    # return unless we have sku, SKU is abosulute must
    # price can be null, as it is for master products but sku has to be set
    return unless product.sku

    fcc = FlowCatalogCache.load_by_country_and_sku exp.country, product.sku
    return unless fcc
    format_price fcc.amount, exp.currency
  end

end
