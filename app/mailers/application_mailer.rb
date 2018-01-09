class ApplicationMailer < ActionMailer::Base
  DEFAULT_FROM = 'solidus@shopflowfashion.com' unless defined?(DEFAULT_FROM)

  default from: DEFAULT_FROM

  layout 'mailer'
end
