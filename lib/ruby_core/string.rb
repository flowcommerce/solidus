# core string modifiers

class String
  # covert names to slugs
  def to_slug
    ret = self.strip.downcase
    ret.gsub!(/['`]/, '')
    ret.gsub!(/\s*@\s*/, ' at ')
    ret.gsub!(/\s*&\s*/, ' and ')
    ret.gsub!(/\s*[^A-Za-z0-9\.\-]\s*/, '-')
    ret.gsub!(/_+/, '-')
    ret.gsub!(/\A[_\.]+|[_\.]+\z/, '')
    ret
  end
end