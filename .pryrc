require 'awesome_print'
require 'clipboard'

# nice object dump in console
Pry.print = proc { |output, data|
  output.puts data.is_a?(Hash) ? JSON.pretty_generate(data) : data.ai
}

class Object
  # copy data to memory
  def cp data
    data = JSON.pretty_generate(data.to_hash) if data.respond_to?(:to_hash)
    Clipboard.copy data
    'copied'
  end

  # json dump objects
  def pjson(object)
    data = if object.respond_to?(:to_hash)
      object.to_hash
    elsif object.respond_to?(:save!)
      object.attributes
    else
      object
    end

    JSON.pretty_generate data
  end
end

# show db we are useing
puts 'ORG: %s' % ENV.fetch('FLOW_ORGANIZATION')
puts ' DB: %s' % ENV.fetch('DB_URL')

