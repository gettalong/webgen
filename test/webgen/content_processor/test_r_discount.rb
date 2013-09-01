# -*- encoding: utf-8 -*-

require 'webgen/test_helper'

class TestRDiscount < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    require 'webgen/content_processor/r_discount' rescue skip('Library rdiscount not installed')
    setup_context
    cp = Webgen::ContentProcessor::RDiscount

    @context.content = '# header'
    assert_equal("<h1>header</h1>\n", cp.call(@context).content)
  end

end
