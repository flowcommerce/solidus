# Flow.io (2017)
# communicates with flow api, easy access
# to basic shop frontend and backend needs

class FlowSession

  def FlowSession.create_for_ip(client, organization, ip)
    client.post_organizations_by_organization(organization, ::Io::Flow::V0::Models::SessionForm(:ip => ip))
  end

  def FlowSession.flag(session, size=32)
    country_code = if session.local
      session.local.country.iso_3166_3
    else
      ENV['FLOW_BASE_COUNTRY'] // e.g. "usa"
    end
    'https://flowcdn.io/util/icons/flags/%s/%s.png' % [size, country_code]
  end

end
