# Flow.io (2017)
# communicates with flow api, responds to webhook events

class Flow::Webhook
  class << self
    def process data
      web_hook = new data
      web_hook.process
    end
  end

  ###

  def initialize(data)
    @data = data
  end

  def process
    @discriminator = @data['discriminator']

    m = 'hook_%s' % @discriminator

    return 'Error: No hook for %s' % @discriminator unless respond_to?(m)
    raise ArgumentError, 'Organization name mismatch for %s' % @data['organization'] if @data['organization'] != Flow.organization

    send(m)
  end

  # hooks

  # // item restriction removed, example payload
  # {
  #   "event_id": "evt-8e388031ff3e445482c231880f7edb45",
  #   "timestamp": "2017-05-02T21:30:30.506Z",
  #   "organization": "solidus-staging",
  #   "number": "660",
  #   "catalog": "master",
  #   "subcatalog_id": "sca-8e515157c52345c7bd846f0b27662eba",
  #   "status": "included",
  #   "discriminator": "subcatalog_item_upserted"
  # }
  def hook_subcatalog_item_upserted
    enable_or_restrict_item
  end

  def hook_rate_upserted
    'ok'
  end

  def hook_localized_item_upserted
    experience_key = @data['local']['experience']['key']
    status         = @data['status']

    enable_or_restrict_item
  end

  private

  # actions

  def enable_or_restrict_item
    raise ArgumentError, 'number not found' unless @data['number']
    raise ArgumentError, 'status not found' unless @data['status']

    # to do, waiting for more info
    if @data['status'] == 'included'
      'item included'
    else
      'item restricted'
    end
  end
end
