# Flow.io (2017)
# module that helps in scheduling of refreshing
# of localized items

module FolwApiRefresh
  class << self
    attr_reader :source_file
  end

  extend self

  @source_file = Rails.root.join('./tmp/last-flow-refresh.txt')

  ###

  def get_data
    @source_file.exist? ? JSON.parse(@source_file.read) : {}
  end

  def write
    data = get_data
    yield data
    @source_file.write data.to_json
    data
  end

  def schedule_refresh!
    write do |data|
      data['force_refresh'] = true
    end
  end

  def log_refresh
    write do |data|
      data['force_refresh'] = false
      data['scheduled'] = Time.now.to_i
    end
  end
end