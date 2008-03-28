module Webgen

  # Mixed into modules/classes that need access to the current website object.
  module WebsiteAccess

    # The methods of this module are available on classes that include WebsiteAccess.
    module ClassMethods

      # See WebsiteAccess.website
      def website
        WebsiteAccess.website
      end

    end

    # :nodoc:
    def self.included(klass)
      super
      klass.extend(ClassMethods)
    end

    # Returns the current website object.
    def website
      Thread.current[:webgen_website]
    end
    module_function :website

  end

end
