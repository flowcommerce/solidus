# Flow.io (2017)
# helper class to manage product sync scheduling

require 'json'
require 'logger'

module FolwApiRefresh
  extend self

  SYNC_INTERVAL_IN_MINUTES = 60 unless defined?(SYNC_INTERVAL_IN_MINUTES)
  CHECK_FILE = Pathname.new './tmp/last-flow-refresh.txt' unless defined?(CHECK_FILE)
  LOGGER = Logger.new('./log/sync.log', 3, 1024000) unless defined?(LOGGER)

  ###

  def get_data
    CHECK_FILE.exist? ? JSON.parse(CHECK_FILE.read) : {}
  end

  def write
    data = get_data
    yield data
    CHECK_FILE.write data.to_json
    data
  end

  def log message
    $stdout.puts message
    LOGGER.info '%s (pid: %d)' % [message, Process.pid]
  end

  def schedule_refresh!
    write do |data|
      data['force_refresh'] = true
    end
  end

  def log_refresh! start=nil
    write do |data|
      data['force_refresh'] = false
      data['duration_in_seconds'] = Time.now.to_i - start.to_i
      data['last'] = Time.now.to_i
    end
  end

  def last_refresh
    json = get_data

    return 'No last sync data' unless json['last']

    diff = (Time.now.to_i - json['last'].to_i)/60

    'Last sync happend %d minutes ago and lasted for %s sec. We sync every %d minutes.' %
      [diff, json['duration_in_seconds'] || '?', SYNC_INTERVAL_IN_MINUTES]
  end

  def sync_products_if_needed!
    json = get_data

    sync_needed = json['force_refresh'] || json['last'].to_i < (Time.now.to_i - SYNC_INTERVAL_IN_MINUTES * 60)

    if sync_needed
      log 'Sync needed, running ...'
      system 'bundle exec rake flow:sync_localized_items'
    else
      log last_refresh
    end
  end
end