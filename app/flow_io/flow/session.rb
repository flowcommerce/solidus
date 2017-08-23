# Flow.io (2017)
# communicates with flow api, easy access to session

class Flow::Session
  attr_accessor :session
  attr_accessor :localized

  # flow session can ve created via IP or local cached OrganizationSession dump
  # Flow::Experience.all.first.key
  def initialize ip:, json: nil, hash: nil, experience: nil
    hash = JSON.load(json) if json

    @session = if experience
      get experience: experience
    elsif hash
      ::Io::Flow::V0::Models::OrganizationSession.new(hash)
    end
  ensure
    # if all fails, get by IP
    @session ||= get ip: ip
  end

  def get opts
    session_model = ::Io::Flow::V0::Models::SessionForm.new opts
    FlowCommerce.instance.sessions.post_organizations_by_organization Flow.organization, session_model
  end

  def change_experience experience
    @session = FlowCommerce.instance.sessions.put_by_session(
      @session.id,
      ::Io::Flow::V0::Models::SessionPutForm.new(experience: experience)
    )
  rescue
    @session = Flow::Session.new(experience: experience).session
  end

  # get local experience or return nil
  def experience
    @session.local ? @session.local.experience : Flow::Experience.default
  end

  # we dump this to session and recreate one from
  def to_hash
    @session.to_hash
  end

  def local
    @session.local
  end

  def id
    @session.id
  end

  def localized?
    # use flow if we are not in default country
    return false unless local
    return false if @localized.class == FalseClass
    local.country.iso_3166_3 != ENV.fetch('FLOW_BASE_COUNTRY').upcase
  end

  # because we do not get full experience from session, we have to get from exp list
  def delivered_duty_options
    Hashie::Mash.new Flow::Experience.get(experience.key).settings.delivered_duty.to_hash
  end

  # if we have more than one choice, we show choice popup
  def offers_delivered_duty_choice?
    delivered_duty_options.available.length > 1
  end
end

