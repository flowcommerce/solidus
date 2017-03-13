class Object

  def r(data=nil)
    data = data.to_a if data.is_a?(Enumerator)
    #raise data.class.to_s
    if data.is_a?(Hash) || data.is_a?(Array)
      raise JSON.pretty_generate(data)
    else
      raise "#{data.class} -> #{data.ai(plain:true)}".gsub('<', '&lt;')
    end
  end

end