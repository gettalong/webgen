# -*- encoding: utf-8 -*-

require 'uri'

module Webgen

  # Namespace for classes and methods that provide common functionality.
  module Common

    # :stopdoc:
    module Callable

      def call(*args, &block)
        new.call(*args, &block)
      end

    end
    # :startdoc:

    autoload :ExtensionManager, 'webgen/common/extension_manager'
    autoload :Sitemap, 'webgen/common/sitemap'

    # Return the constant object for the given absolute constant +name+.
    def self.const_for_name(name)
      name.split('::').inject(Object) {|b,n| b.const_get(n)}
    end

    # Transform the string in Module::CamelCase format into module/camel_case format.
    def self.snake_case(str)
      str = str.dup
      str.gsub!(/::/, '/')
      str.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      str.gsub!(/([a-z])([A-Z])/,'\1_\2')
      str.downcase!
      str
    end

    # This pattern is the the same as URI::UNSAFE except that the hash character (#) is also
    # not escaped. This is needed so that paths with fragments work correctly.
    URL_UNSAFE_PATTERN = Regexp.new("[^#{URI::PATTERN::UNRESERVED}#{URI::PATTERN::RESERVED}#]") # :nodoc:

    # Construct an internal URL for the given +name+ which can be an acn/alcn/absolute path. If the
    # parameter +make_absolute+ is +true+, then a relative URL will be made absolute by prepending
    # the special URL <tt>webgen:://webgen.localhost/</tt>.
    def self.url(name, make_absolute = true)
      url = URI.parse(URI::escape(name, URL_UNSAFE_PATTERN))
      url = URI.parse('webgen://webgen.localhost/') + url unless url.absolute? || !make_absolute
      url
    end

    # Append the +path+ to the +base+. The +base+ parameter has to be an acn/alcn/absolute path. If
    # it represents a directory, it has to have a trailing slash! The +path+ parameter doesn't need
    # to be absolute and may contain path patterns.
    def self.append_path(base, path)
      raise(ArgumentError, 'base needs to start with a slash (i.e. be an absolute path)') unless base =~ /^\//
      url = url(base) + url(path, false)
      url.path + (url.fragment.nil? ? '' : '#' + url.fragment)
    end

  end

end
