module Webgen

  # Namespace for all classes that know how to write out node content.
  #
  # = Implementing an output class
  #
  # Output classes know how to write rendered node data to an output location.
  #
  # An output class must respond to three methods
  #
  # <tt>exists?(path)</tt>::
  #   Return +true+ if the output path exists.
  # <tt>delete(path)</tt>::
  #   Delete the given output path.
  # <tt>write(path, data, type)</tt>::
  #   Write the data to the given output path. The parameter +type+ specifies the type of the
  #   to be written path: +:file+ or +:directory+.
  #
  module Output

    autoload :FileSystem, 'webgen/output/filesystem'

  end

end
