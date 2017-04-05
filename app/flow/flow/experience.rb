# Flow.io (2017)
# communicates with flow api, easy access
# to basic shop frontend and backend needs

module Flow::Experience
  extend self

  def all(no_world=nil)
    experiences = get_from_flow
    no_world ? experiences.select{ |exp| exp.key != 'world' } : experiences
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

  private

  def get_from_flow
    # cache experinces in current thread for 1 minute
    return @cache[0] if @cache && @cache[1] > Time.now - 1.minute
    experiences = FlowCommerce.instance.experiences.get(Flow.organization)
    @cache = [experiences, Time.now]
    experiences
  end

end