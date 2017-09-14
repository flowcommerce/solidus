# set root unless for some reson not in right root
Dir.chdir File.expand_path('../..', __FILE__)

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'dotenv'

Dotenv.load

ENV['LANG'] = 'en_US.UTF-8'

# allow setting of RACK_ENV or RAILS_ENV
ENV['RACK_ENV']  ||= ENV['RAILS_ENV']
ENV['RAILS_ENV'] ||= ENV['RACK_ENV']

# ensure env is defined
ENV.fetch('RAILS_ENV')
ENV.fetch('SECRET_TOKEN')
ENV.fetch('SECRET_KEY_BASE')
ENV.fetch('FLOW_API_KEY')
ENV.fetch('FLOW_ORGANIZATION')
ENV.fetch('FLOW_BASE_COUNTRY')

# for comaptibility with flowcommrece gem
ENV['FLOW_TOKEN'] = ENV['FLOW_API_KEY']
