# -*- encoding: utf-8 -*-

# :nodoc:
class Array

  def to_hash # :nodoc:
    h = {}
    self.each {|k,v| h[k] = v}
    h
  end

end
