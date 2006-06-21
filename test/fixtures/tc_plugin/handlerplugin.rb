module Testing

  class BaseHandler < Webgen::HandlerPlugin
  end

  class Handler1 < BaseHandler

    register_handler 'handler1'

  end

  class Handler2 < BaseHandler
  end

end
