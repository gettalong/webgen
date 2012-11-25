# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/r_doc'

class TestRDoc < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_static_call
    setup_context
    cp = Webgen::ContentProcessor::RDoc

    @context.content = "* hello"
    assert_equal("<ul><li><p>hello</p></li></ul>", cp.call(@context).content.tr("\n", ''))
  end

end
