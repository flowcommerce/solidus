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
    ap @data['discriminator']

    m = 'hook_%s' % @discriminator

    return 'Error: No hook for %s' % @discriminator unless respond_to?(m)
    raise ArgumentError, 'Organization name mismatch for %s' % @data['organization'] if @data['organization'] != Flow.organization

    send(m)
  end

  # hooks

  def hook_localized_item_upserted
    raise ArgumentError, 'number not found' unless @data['number']
    raise ArgumentError, 'local not found' unless @data['local']

    variant = Spree::Variant.find @data['number']
    product = variant.product
    key     = '%s.excluded' % @data['local']['experience']['key']

    # if item is included, set key, otherwise delete it
    if @data['local']['status'] == 'included'
      product.flow_data[key] = 1
    else
      product.flow_data.delete(key)
    end

    product.save!
  end
end
