module Flow
  extend self

  def experiences
    yml_path = './config/flow_experiences.yml'

    raise StandardError, 'Experiences yaml not found in %s' % yml_path unless File.exists?(yml_path)

    list = YAML.load_file yml_path

    # return hash that we can access with
    list.map { |el| ActiveSupport::HashWithIndifferentAccess.new(el) }
  end

end