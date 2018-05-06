# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/css_minify'

class TestContentProcessorCSSMinify < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    setup_context
    cp = Webgen::ContentProcessor::CSSMinify

    @context.content = "a   \n{    border: 1px   solid   #000000\n}"
    assert_equal("a{border:1px solid #000}", cp.call(@context).content)
  end

end
