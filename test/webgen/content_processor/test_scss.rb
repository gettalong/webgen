# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/content_processor/scss'

class TestScss < MiniTest::Unit::TestCase

  include Test::WebgenAssertions

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    cp = Webgen::ContentProcessor::Scss

    context.content = "#main {background-color: #000}"
    assert_equal("#main {\n  background-color: #000; }\n", cp.call(context).content)

    context.content = "#cont\n = 5"
    assert_error_on_line(Webgen::RenderError, 2) { cp.call(context) }
  end

end
