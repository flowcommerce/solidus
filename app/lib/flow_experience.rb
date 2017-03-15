# Flow.io (2017)
# communicates with flow api, easy access
# to basic shop frontend and backend needs

module FlowExperience
  extend self

  def all
    # cache experinces in current thread for 1 minute
    return @cache[0] if @cache && @cache[1] > Time.now - 1.minute
    experiences = FlowCommerce.instance.experiences.get(ENV.fetch('FLOW_ORG'))
    experiences = experiences.select{ |exp| exp.key != 'world' }
    @cache = [experiences, Time.now]
    experiences
  end

  def keys
    all.map{ |el| el.key }
  end

  def get(key)
    all.each do |exp|
      return exp if exp.key == key
    end
    nil
  end
end