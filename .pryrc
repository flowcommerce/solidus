require "awesome_print"

# nice object dump in console
Pry.print = proc { |output, value| output.puts value.ai }

# exit on ctrl+c
# Signal.trap('INT') { puts; exit }

# show db we are useing
puts "DB: #{ENV['DB_URL']}"

