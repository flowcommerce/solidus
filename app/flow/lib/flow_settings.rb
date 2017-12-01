class FlowSettings < ActiveRecord::Base

  # create or set value with timestamp
  def self.set key, value
    settings            = find_or_initialize_by key: key
    settings.data       = value
    settings.created_at = DateTime.new
    settings.save

    value
  end

  def self.get key
    settings = find_by key: key
    settings ? settings.data : nil
  end

end