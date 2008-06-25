module Webgen

  # Namespace for all classes that provide source paths.
  #
  # = Implementing a source class
  #
  # Source classes provide access to the source paths on which the source handlers act.
  #
  # A source class only needs to respond to the method +paths+ which needs to return a set of paths
  # for the source. The returned paths must respond to the method <tt>changed?</tt> (has to return
  # +true+ if the paths has changed since the last webgen run) which is not implemented in the
  # default Path class. One can either derive a specialized path class or define singleton methods
  # on each path object.
  #
  module Source

    autoload :Base, 'webgen/source/base'
    autoload :FileSystem, 'webgen/source/filesystem'
    autoload :Stacked, 'webgen/source/stacked'

  end

end
