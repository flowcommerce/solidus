# http is more reliable than https, keep
source 'http://rubygems.org'

# ruby '2.3.3'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# basics
gem 'rails', '5.1.4'
gem 'pg', '< 1.0'
gem 'hashie'
gem 'tzinfo-data'
gem 'colorize'
gem 'pry-rails'                # better console
gem 'awesome_print'
gem 'flowcommerce'
gem 'flowcommerce-activemerchant'
gem 'rails_before_render'

# solidus fw
gem 'solidus', '2.4.2',    require: false
gem 'solidus_auth_devise', require: false
gem 'dotenv',              require: false
gem 'faraday',             require: false
gem 'thread',              require: false

group :development do
  # gem 'spring'                           # fast console and tests
  gem 'puma'
  gem 'listen', '~> 3.0.5'
  gem 'letter_opener'                     # preview email in development
  gem 'clipboard'

  # css and js block
  gem 'therubyracer', platforms: :ruby
  gem 'sass-rails', '~> 5.0'
  gem 'uglifier', '>= 1.3.0'
  gem 'coffee-rails', '~> 4.2'
  gem 'turbolinks', '~> 5'
end

group :production do
  gem 'bugsnag'
  gem 'newrelic_rpm'
  gem 'rack-timeout', require: 'rack/timeout/base' # Rack::Timeout is important for avoiding stuck Puma workers/threads on server:
end

group :test do
  gem 'rspec-rails'
end