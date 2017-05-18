# Flow (2017)
# for flow errors

require 'digest/sha1'

class Flow::Error < StandardError

  # logs error to file for easy discovery and fix
  def self.log(exception, request)
    history = exception.backtrace.reject{ |el| el.index('/gems/') }.map{ |el| el.sub(Rails.root.to_s, '') }.join($/)

    msg  = '%s in %s' % [exception.class, request.url]
    data = [msg, exception.message, history].join("\n\n")
    key  = Digest::SHA1.hexdigest exception.backtrace.first.split(' ').first

    folder = Rails.root.join('log/exceptions').to_s
    Dir.mkdir(folder) unless Dir.exists?(folder)

    folder += "/#{exception.class.to_s.tableize.gsub('/','-')}"
    Dir.mkdir(folder) unless Dir.exists?(folder)

    "#{folder}/#{key}.txt".tap do |path|
      File.write(path, data)
    end
  end

end
