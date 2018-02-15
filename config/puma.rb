# ensure we have a right root folder
Dir.chdir(__FILE__.sub('/config/puma.rb','')) if __FILE__ != 'config/puma.rb'

require 'dotenv'
Dotenv.load

port    3000
threads 1, 16

if ENV.fetch('RACK_ENV') == 'production'
  # workers 2

  preload_app!

  on_worker_boot do
    ActiveRecord::Base.establish_connection
  end

  before_fork do
    # require 'puma_worker_killer'
    # PumaWorkerKiller.enable_rolling_restart 3 * 3600
  end

  # # refresh and sync products
  # if ENV['SYNC_PRODUCTS'] == 'true'
  #   puts '* product sync enabled'
  #   require './app/flow/lib/flow_api_refresh'

  #   Thread.new do
  #     while true
  #       FolwApiRefresh.sync_products_if_needed!

  #       sleep 3600
  #     end
  #   end
  # end
end
