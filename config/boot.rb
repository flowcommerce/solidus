# set root unless for some reson not in right root
Dir.chdir File.expand_path('../..', __FILE__)

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# better way to do it, if there is dot env file, load it
if File.exists?('./.env')
  require 'dotenv'
  Dotenv.load
end

# allow setting of RACK_ENV or RAILS_ENV
ENV['RACK_ENV']  ||= ENV['RAILS_ENV']
ENV['RAILS_ENV'] ||= ENV['RACK_ENV']

# ensure env is defined
ENV.fetch('RAILS_ENV')
ENV.fetch('SECRET_TOKEN')
ENV.fetch('SECRET_KEY_BASE')
