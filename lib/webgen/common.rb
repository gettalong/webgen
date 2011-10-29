# -*- encoding: utf-8 -*-

module Webgen

  # Namespace for classes and methods that provide common functionality.
  module Common

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

  end

end
