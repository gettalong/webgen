# -*- encoding: utf-8 -*-

require 'rbconfig'
require 'webgen/core_ext'

module Webgen

  # Namespace for classes and methods that provide common functionality.
  module Utils

    # Return the data directory for webgen.
    def self.data_dir
      unless defined?(@@data_dir)
        require 'rbconfig'
        @@data_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data', 'webgen'))
        @@data_dir = File.expand_path(File.join(RbConfig::CONFIG["datadir"], "webgen")) if !File.exists?(@@data_dir)
        raise "Could not find webgen data directory! This is a bug, report it please!" unless File.directory?(@@data_dir)
      end
      @@data_dir
    end

    # Return the object for the given absolute constant +name+.
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
