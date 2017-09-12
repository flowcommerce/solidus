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
    LOGGER.info '%s (pid/ppid: %d/%d)' % [message, Process.pid, Process.ppid]
  end

  def schedule_refresh!
    write do |data|
      data['force_refresh'] = true
    end
  end

  def log_refresh! start_time=nil
    write do |data|
      if start_time
        data['force_refresh'] = false
        data['duration_in_seconds'] = Time.now.to_i - start_time.to_i if start_time
        data['start'] = start_time.to_i
        data['end']   = Time.now.to_i
        data.delete('started')
      else
        data['started'] = true
        data['start'] = Time.now.to_i
      end
    end
  end

  def last_refresh
    json = get_data

    return 'No last sync data' unless json['end']

    info = []

    info.push 'Sync started %d seconds ago (it is in progress).' % (Time.now.to_i - json['start'].to_i) if json['started']

    info.push 'Last sync finished %{finished} minutes ago and lasted for %{duration} sec. We sync every %{every} minutes.' %
      {
        finished: (Time.now.to_i - json['end'].to_i)/60,
        duration: json['duration_in_seconds'] || '?',
        every:    SYNC_INTERVAL_IN_MINUTES
      }

    info.join(' ')
  end

  def sync_products_if_needed!
    json = get_data

    sync_needed = false

    unless json['started']
      sync_needed ||= true if json['force_refresh']
      sync_needed ||= true if json['start'].to_i < (Time.now.to_i - SYNC_INTERVAL_IN_MINUTES * 60)
    end

    if sync_needed
      log 'Sync needed, running ...'
      system 'bundle exec rake flow:sync_localized_items'
    else
      log last_refresh
    end
  end
end