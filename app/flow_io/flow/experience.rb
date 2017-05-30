# Flow.io (2017)
# communicates with flow api, easy access
# to basic shop frontend and backend needs

module Flow::Experience
  extend self

  def all no_world=nil
    experiences = get_from_flow
    no_world ? experiences.select{ |exp| exp.key != 'world' } : experiences
  end

  def keys
    all.map{ |el| el.key }
  end

  def get key
    all.each do |exp|
      return exp if exp.key == key
    end
    nil
  end

  def default
    all.first
  end

  # because we do not get full experience from session, we have to get from exp list
  def delivered_duty experience
    key = experience.is_a?(String) ? experience : experience.key
    Hashie::Mash.new get(key).settings.delivered_duty.to_hash
  end

  # if we have 2 choices, we show choice popup
  def delivered_duty? experience
    return false unless experience
    delivered_duty(experience).available.length == 2
  end

  private

  def get_from_flow
    return cached_experinces if cache_valid?

    experiences = FlowCommerce.instance.experiences.get(Flow.organization)
    @cache = [experiences, Time.now]
    experiences
  end

  def cache_valid?
    # cache experinces in worker memory for 1 minute
    @cache && @cache[1] > Time.now.ago(1.minute)
  end

  def cached_experinces
    @cache[0]
  end

end