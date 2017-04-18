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

module DemoShop
  class Application < Rails::Application

    # solidus overrides
    config.to_prepare do
      overload = Dir.glob('./app/flow_io/**/*.rb')
      overload.reverse.each { |c| load(c) }
    end

    config.after_initialize do |app|
      app.config.spree.payment_methods << Spree::Gateway::Flow

      Flow.organization = ENV.fetch('FLOW_ORGANIZATION')
      Flow.base_country = ENV.fetch('FLOW_BASE_COUNTRY')
      Flow.api_key      = ENV.fetch('FLOW_API_KEY')

      ActionMailer::Base.default_url_options[:host] = Spree::Store.find_by(default:true).url
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

