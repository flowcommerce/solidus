require 'spec_init'

class SpreeVariantMock
  class << self
    def find(id)
      raise 'Number does not match' unless id == '1233456'
      new id
    end

    def find_by opts
      raise 'Number does not match' unless opts[:id] == '1233456'
      new opts[:id]
    end
  end

  ###

  def initialize number
    @number = number
  end

  def id
    @number
  end

  def product
    SpreeProductMock.new @number
  end
end

class SpreeProductMock
  def initialize id
    @id   = id.to_i * 2
    @data = {}
  end

  def id
    @id
  end

  def name
    'Product mock'
  end

  def flow_data
    @data
  end

  def save!
    true
  end
end

RSpec.describe Flow::Webhook do
  let(:variant_number) { '1233456' }
  let(:experience_key) { 'utopia' }

  let(:localized_event_data) {
    {
      'discriminator' => 'localized_item_upserted',
      'organization'  => Flow.organization,
      'number'        => variant_number,
      'local' => {
        'experience' => {'key'   => experience_key},
        'status'     => 'included'
      }
    }
  }

  ###

  it 'tests localized item upserted - included' do
    opts     = { variant_class: SpreeVariantMock }
    web_hook = Flow::Webhook.new localized_event_data, opts
    message  = web_hook.process

    expect(message).to eq('Product id:2466912 - "Product mock" (from variant %d) included in experience "%s"' % [variant_number, experience_key])
    expect(web_hook.product.flow_data['%s.excluded' % experience_key]).to eq(0)
  end

  it 'tests localized item upserted - excluded' do
    excluded_data = localized_event_data.dup
    excluded_data['local']['status'] = 'excluded'

    opts     = { variant_class: SpreeVariantMock }
    web_hook = Flow::Webhook.new excluded_data, opts
    message  = web_hook.process

    expect(message).to eq('Product id:2466912 - "Product mock" (from variant %d) excluded from experience "%s"' % [variant_number, experience_key])
    expect(web_hook.product.flow_data['%s.excluded' % experience_key]).to eq(1)
  end
end
