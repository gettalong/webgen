# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/rdiscount'

class TestRDiscount < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_static_call
    setup_context
    cp = Webgen::ContentProcessor::RDiscount

    @context.content = '# header'
    assert_equal("<h1>header</h1>\n", cp.call(@context).content)
  end

end
