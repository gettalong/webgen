module Tag
  class TestTag < DefaultTag

    def initialize
      super
      register_tag('test')
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
