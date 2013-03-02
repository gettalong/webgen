# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/rainpress'

class TestContentProcessorRainpress < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_static_call
    setup_context
    @website.config['content_processor.rainpress.options'] = {}
    cp = Webgen::ContentProcessor::Rainpress

    @context.content = "a   \n{    border: 1px   solid   bold\n}"
    assert_equal("a{border:1px solid bold}", cp.call(@context).content)
  end

end
