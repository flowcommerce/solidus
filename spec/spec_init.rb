# prepare test env
ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'
ENV['DB_URL']   = ENV['DB_TEST_URL'] || 'postgres://localhost/flow_solidus_demo_test'

# load rails, models, rspec
require './config/environment'

# load config
require 'spec_config'

# show db url
puts 'db url: %s' % ENV['DB_URL']

# ensure we are in test env
abort 'The Rails environment is not running in test mode!' unless Rails.env.test?
