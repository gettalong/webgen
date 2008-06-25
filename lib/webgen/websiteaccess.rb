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

    def self.included(klass) #:nodoc:
      super
      klass.extend(ClassMethods)
    end

    # Return the current website object or +nil+.
    def website
      Thread.current[:webgen_website]
    end
    module_function :website

  end

end
