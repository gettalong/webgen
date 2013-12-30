# -*- encoding: utf-8 -*-

module Webgen
  class Tag

    # Prints out the date using a format string which will be passed to Time#strftime. Therefore you
    # can use everything Time#strftime offers.
    module Date

      # Return the current date formatted as specified.
      def self.call(tag, body, context)
        key = context[:config]['tag.date.mi']
        val = context.content_node[key]

        if val && val.respond_to?(:strftime)
          time = val
        elsif val
          raise Webgen::RenderError.new("Value of meta information key '#{key}' not a valid date/time",
                                        "tag.date", context.dest_node, context.ref_node)
        elsif key
          raise Webgen::RenderError.new("No meta information key '#{key}' found",
                                        "tag.date", context.dest_node, context.ref_node)
        else
          time = Time.now
        end
        time.strftime(context[:config]['tag.date.format'])
      end

    end

  end
end
