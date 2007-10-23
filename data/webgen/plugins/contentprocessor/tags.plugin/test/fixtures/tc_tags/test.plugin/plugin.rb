module Tag
  class TestTag

    def tags
      [:default]
    end

    def set_params(*args)
    end

    def tag_params(*args)
    end

    def process_tag( tag, body, context )
      case tag
      when 'body'
        body
      when 'bodyproc'
        [body, true]
      else
        tag
      end
    end

  end
end
