require 'dotenv'
Dotenv.load

port    3000
threads 0, 8

if ENV.fetch('RACK_ENV') == 'production'
  workers 2

  # on_worker_boot do
  #   ActiveRecord::Base.establish_connection
  # end

  before_fork do
    require 'puma_worker_killer'
    PumaWorkerKiller.enable_rolling_restart 3 * 3600
  end

  # refresh and sync products
  require './app/flow/lib/flow_api_refresh'
  Thread.new do
    while true
      FolwApiRefresh.sync_products_if_needed!
      sleep 59
    end
  end
end

