class Object

  def r(what=nil)
    res = what.kind_of?(String) ? "String -> #{what}" : what.ai(plain:true)#"#{what.class.name} -> #{what.to_json}"
    raise res.gsub('<', '&lt;')
  end

end