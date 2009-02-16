# -*- encoding: utf-8 -*-

module Webgen::Tag

  # Prints out the date using a format string which will be passed to Time#strftime. Therefore you
  # can use everything Time#strftime offers.
  class Date

    include Base

    # Return the current date formatted as specified.
    def call(tag, body, context)
      Time.now.strftime(param('tag.date.format'))
    end

  end

end
