require_relative 'boot'

# load only what we need
require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "action_cable/railtie"
# require "active_job/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require './lib/ruby_core/object'
require './lib/ruby_core/string'

module DemoShop
  class Application < Rails::Application

    # solidus overrides
    config.to_prepare do
      overload  = Dir.glob('./app/**/*_decorator*.rb')
      overload += Dir.glob('./app/overrides/*.rb')
      overload.each { |c| load(c) }
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
