module Webgen

  class Context

    # Returns the result of evaluating the webgen tag +name+ with the tag parameters +params+ and
    # the +body+ in the current context.
    #
    # Have a look at Webgen::Tag::Base for more information about webgen tags!
    #
    # This method is useful when you want to have the functionality of webgen tags available but you
    # don't want to use the content processor for them. Or, for example, if the used markup language
    # uses a similar markup as webgen tags do and therefore you can't use the normal webgen tags
    # content processor.
    def tag(name, params = {}, body = '')
      website.cache.instance('Webgen::ContentProcessor::Tags').process_tag(name, params, body, self)
    end

  end

end
