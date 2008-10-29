require 'pathname'

module Webgen

  # Namespace for classes and methods that provide common functionality.
  module Common

    autoload :Sitemap, 'webgen/common/sitemap'

    # Make the given +path+ absolute by prepending the absolute path +base+ if necessary. Also
    # resolves all '..'  and '.' references in +path+.
    def self.absolute_path(path, base)
      raise(ArgumentError, 'base has to be an absolute path') unless base =~ /\//
      Pathname.new(path =~ /^\// ? path : File.join(base, path)).cleanpath.to_s
    end

  end

end
