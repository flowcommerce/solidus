# Flow.io (2017)
# helper class to manage product sync scheduling

module FolwApiRefresh
  extend self

  SYNC_INTERVAL_IN_MINUTES = 60
  CHECK_FILE = Pathname.new './tmp/last-flow-refresh.txt'

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

  def log_refresh!
    write do |data|
      data['force_refresh'] = false
      data['last'] = Time.now.to_i
    end
  end

  def sync_products_if_needed!
    json = get_data

    sync_needed = json['force_refresh'] || # set by flow admin
                  json['last'].to_i < Time.now.to_i - SYNC_INTERVAL_IN_MINUTES * 60

    if sync_needed
      puts 'Sync needed, running ...'
      system 'bundle exec rake flow:sync_localized_items'

    else
      diff = (Time.now.to_i - json['last'].to_i)/60
      return puts 'Last sync happend %d minutes ago. We sync every %d minutes.' % [diff, SYNC_INTERVAL_IN_MINUTES]

    end
  end
end