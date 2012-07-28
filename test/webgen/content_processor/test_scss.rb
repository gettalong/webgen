# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/scss'

class TestScss < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_static_call
    setup_context
    @website.expect(:config, {'content_processor.sass.options' => {}})
    @website.ext.sass_load_paths = []
    cp = Webgen::ContentProcessor::Scss

    @context.content = "#main {background-color: #000}"
    assert_equal("#main {\n  background-color: #000; }\n", cp.call(@context).content)

    @context.content = "#cont\n = 5"
    assert_error_on_line(Webgen::RenderError, 2) { cp.call(@context) }
  end

end
