# auto flush and add global custom logger to development
if Rails.env.development?
  log_file = File.open('./log/custom.log', 'w')
  log_file.sync = true
  $log = Logger.new(log_file)
end
