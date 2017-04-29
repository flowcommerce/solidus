# Flow.io (2017)
# communicates with flow api, easy access to session
# to basic shop frontend and backend needs

class Flow::Session
  attr_accessor :session

  def get(opts)
    session_model = ::Io::Flow::V0::Models::SessionForm.new(opts)
    FlowCommerce.instance.sessions.post_organizations_by_organization(Flow.organization, session_model)
  end

  # flow session can ve created via IP or local cached OrganizationSession dump
  # Flow::Experience.all.first.key
  def initialize(ip: nil, hash: nil, experience: nil)
    @session = if experience
      get experience: experience
    elsif ip
      get ip: ip
    elsif hash
      ::Io::Flow::V0::Models::OrganizationSession.new(hash)
    else
      raise 'IP, hash or experience needed'
    end
  end

  def change_experience(experience)
    @session = FlowCommerce.instance.sessions.put_by_session(
      @session.id,
      ::Io::Flow::V0::Models::SessionPutForm.new(experience: experience)
    )
  rescue
    @session = Flow::Session.new(experience: experience).session
  end

  # we dump this to session and recreate one from
  def to_hash
    @session.to_hash
  end

  def local
    # @session.local.country
    # @session.local.currency
    # @session.local.experience
    # @session.local.language

    @session.local
  end

  def use_flow?
    # use flow if we are not in default country
    local.country.iso_3166_3 != ENV.fetch('FLOW_BASE_COUNTRY')
  end
end

