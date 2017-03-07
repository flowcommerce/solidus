# Flow.io (2017)
# communicates with flow api, easy access
# to basic shop frontend and backend needs

class FlowExperience < Hash
  class << self

    EXPERIENCES_PATH = './config/flow_experiences.yml'
    raise StandardError, 'Experiences yaml not found in %s' % EXPERIENCES_PATH unless File.exists?(EXPERIENCES_PATH)

    # gets localy cached expiriences
    # prebuild cache with "rake flow:get_experiences"
    # "https://flowcdn.io/util/icons/flags/32/%s.png" % el['region']['id']
    def all
      YAML.load_file(EXPERIENCES_PATH).map { |el|
        ActiveSupport::HashWithIndifferentAccess.new(el)
      }
    end

    def organization
      ENV.fetch('FLOW_ORG')
    end

    # get only local country codes
    def keys
      all.map{ |el| el['key'] }
    end

    # get country defaults
    # https://docs.flow.io/#/module/geolocation
    def country_defaults(ip)
      data = Flow.api :get, '/geolocation/defaults', ip: ip
      data.first
    end

    # get experience for an IP or get first one cached as default experience
    # croatia '188.129.64.124'
    # canada  '192.206.151.131'
    # japan   '45.63.127.114'
    def country_key_by_ip(ip)
      FlowCommerce.instance.experiences.get(organization, ip: ip).first.key
    rescue
      all.first['key']
    end

    # gets Flow session by IP
    def session_by_ip
      # r FlowCommerce::Models::V0::OrganizationSessionForm( organization: organization, ip: request.ip)
    end

    def init_by_key(experience_key)
      current_exp = all.select { |exp| exp['key'] == experience_key }[0]
      raise StandardError, 'Experience "%s" not found' % current_key unless current_exp
      new current_exp
    end

  end

  ###

  def initialize(experience)
    keys = [:id, :key, :name, :delivered_duty, :country, :currency, :language, :measurement_system]
    keys.each { |key|
      self[key] = experience[key].freeze
    }
    self[:region_id] = experience[:region][:id]
  end

  def key
    self[:key]
  end

  def currency
    self[:currency]
  end

  def organization
    self.class.organization
  end

  # gets item by number or just pass spree variant or spree product
  def get_item(object)
    number = object.respond_to?(:flow_number) ? object.flow_number : object.to_s

    raise ArgumentError, 'Flow number "%s" is not prefixed by s-variant' % number unless number[0,9] == 's-variant'

    FlowCommerce.instance.experiences.get_items_by_number organization, number, country: key
  end
end