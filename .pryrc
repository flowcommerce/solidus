Signal.trap('INT') { puts; exit }

puts "DB: #{ENV['DB_URL']}"

