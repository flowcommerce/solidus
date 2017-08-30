# Flow.io (2017)
# helper class to manage product sync scheduling

module FolwApiRefresh
  extend self

  SYNC_INTERVAL_IN_MINUTES = 60 unless defined?(SYNC_INTERVAL_IN_MINUTES)
  CHECK_FILE = Pathname.new './tmp/last-flow-refresh.txt' unless defined?(CHECK_FILE)

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

    info = []
    info.push 'Last sync happend %d minutes ago.' % diff
    info.push 'We sync every %d minutes.'         % SYNC_INTERVAL_IN_MINUTES
    info.push 'Last sync took %d seconds.'        % json['duration_in_seconds'] if json['duration_in_seconds']
    info.join($/)
  end

  def sync_products_if_needed!
    json = get_data

    sync_needed = json['force_refresh'] || # set by flow admin
                  json['last'].to_i < Time.now.to_i - SYNC_INTERVAL_IN_MINUTES * 60

    if sync_needed
      puts 'Sync needed, running ...'
      system 'bundle exec rake flow:sync_localized_items'
    else
      return puts last_refresh
    end
  end
end