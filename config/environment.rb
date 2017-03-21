# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

DemoShop::Application.config.spree.payment_methods << Spree::Gateway::Flow