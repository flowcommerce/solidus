# Flow.io (2017)
# communicates with flow api, easy access to session
# to basic shop frontend and backend needs

class FlowSession

  def get(opts)
    session_model = ::Io::Flow::V0::Models::SessionForm.new(opts)
    FlowCommerce.instance.sessions.post_organizations_by_organization(ENV.fetch('FLOW_ORG'), session_model)
  end

  # flow session can ve created via IP or local cached OrganizationSession dump
  # FlowExperience.all.first.key
  def initialize(ip: nil, hash: nil, experience: nil)
    @session = if ip
      session = get ip: ip

      # if local is not found based on IP, get session by first defined experience
      #session = get experience: FlowExperience.all.first.key unless session.local
      session
    elsif hash
      ::Io::Flow::V0::Models::OrganizationSession.new(hash)
    elsif experience
      get experience: experience
    end
  end

  def change_experience(experience)
    @session = FlowCommerce.instance.sessions.put_by_session(
      @session.id,
      ::Io::Flow::V0::Models::SessionPutForm.new(experience: experience)
    )
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

end

