# -*- encoding: utf-8 -*-

# :stopdoc:
class Array

  def to_hash
    h = {}
    self.each {|k,v| h[k] = v}
    h
  end

end
# :startdoc:
