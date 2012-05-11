# -*- encoding: utf-8 -*-

module Webgen
  class Tag

    # Prints out the date using a format string which will be passed to Time#strftime. Therefore you
    # can use everything Time#strftime offers.
    module Date

      # Return the current date formatted as specified.
      def self.call(tag, body, context)
        Time.now.strftime(context[:config]['tag.date.format'])
      end

    end

  end
end
