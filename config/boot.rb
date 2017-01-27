# set root unless for some reson not in right root
Dir.chdir File.expand_path('../..', __FILE__)

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# better way to do it, if there is dot env file, load it
if File.exists?('./.env')
  require 'dotenv'
  Dotenv.load
end

# rack env has to be defined and overrides rails env
ENV['RAILS_ENV'] = ENV.fetch('RACK_ENV')

# ensure secrets are defined
ENV.fetch('SECRET_TOKEN')
ENV.fetch('SECRET_KEY_BASE')
