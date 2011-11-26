# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/content_processor/rdoc'

class TestRDoc < MiniTest::Unit::TestCase

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    cp = Webgen::ContentProcessor::RDoc
    context.content = "* hello"
    assert_equal("<ul><li><p>hello</p></li></ul>", cp.call(context).content.tr("\n", ''))
  end

end
