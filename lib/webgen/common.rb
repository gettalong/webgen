# -*- encoding: utf-8 -*-

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

    # Return the error line by inspecting the backtrace of the given +error+ instance.
    def self.error_line(error)
      (error.is_a?(::SyntaxError) ? error.message : error.backtrace[0]).scan(/:(\d+)/).first.first.to_i rescue nil
    end

    # Return the file name where the error occured.
    def self.error_file(error)
      (error.is_a?(::SyntaxError) ? error.message : error.backtrace[0]).scan(/(?:^|\s)(.*?):(\d+)/).first.first
    end

  end

end
