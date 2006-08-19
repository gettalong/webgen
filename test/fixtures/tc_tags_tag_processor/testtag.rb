module Testing

  class TestTag < Tags::DefaultTag

    register_tag 'test'

    param 'test', nil, ''
    set_mandatory 'test', true

    def initialize( plugin_manager )
      super
      register_tag 'test1'
    end

  end

end
