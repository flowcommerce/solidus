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

    number  = @data['number']
    exp_key = @data['local']['experience']['key']

    variant     = Spree::Variant.find number
    product     = variant.product
    is_included = @data['local']['status'] == 'included'

    product.flow_data['%s.excluded' % exp_key] = is_included ? 0 : 1
    product.save!

    message = is_included ? 'included in' : 'excluded from'
    'Product id:%s - "%s" (from variant %s) %s experience "%s"' % [product.id, product.name, variant.id, message, exp_key]
  end

  # we should consume only localized_item_upserted
  def hook_subcatalog_item_upserted
    'not used'
  end
end
