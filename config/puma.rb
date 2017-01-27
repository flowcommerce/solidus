# load .env if exists
if File.exists?('./.env')
  require 'dotenv'
  Dotenv.load
end

# RACK_ENV from RAILS_ENV if defined
ENV['RACK_ENV'] ||= ENV['RAILS_ENV']

# die unless RACK_ENV set
raise LoadError, 'RACK_ENV is not set' unless ENV['RACK_ENV']

# check if in supported environments
unless ['development', 'test', 'production'].index(ENV['RACK_ENV'])
  raise LoadError, "RACK_ENV #{ENV['RACK_ENV']} is not supported"
end

# add more workers to production
if ENV['RACK_ENV'] == 'production'
  threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
  threads threads_count, threads_count
  workers Integer(ENV['WEB_CONCURRENCY'] || 2)
  preload_app!
end

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV']

on_worker_boot do
  ActiveRecord::Base.establish_connection
end
