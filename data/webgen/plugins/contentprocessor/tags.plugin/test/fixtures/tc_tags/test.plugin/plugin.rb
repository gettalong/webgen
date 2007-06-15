module Tag
  class TestTag

    def tags
      [:default]
    end

    def set_tag_config(*args)
    end

    def reset_tag_config(*args)
    end

    def process_tag( tag, body, ref_node, node )
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
