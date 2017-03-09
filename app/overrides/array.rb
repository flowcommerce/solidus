class Array
  def hash_by_key(key)
    self.inject({}) do |hash, el|
      hash[el.delete(key)] = el
      hash
    end
  end
end
