# -*- encoding: utf-8 -*-

require 'webgen/error'

# Require the given library but handle a possible loading error more gracefully.
#
# The parameter +gem+ (which defaults to +library+) should be set to the Rubygem that provides the
# library or to +nil+ if no such Rubygem exists.
def webgen_require(library, gem = library)
  require library
rescue LoadError
  raise Webgen::LoadError.new(library, self.class.name, nil, gem)
end


class Hash

  # Return a new hash where all String keys are converted to Symbol keys.
  def symbolize_keys
    hash = dup
    hash.keys.each {|k| hash[(k.to_sym rescue k)] = hash.delete(k)}
    hash
  end

end
