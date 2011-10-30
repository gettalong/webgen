# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/content_processor/rdiscount'

class TestRDiscount < MiniTest::Unit::TestCase

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    cp = Webgen::ContentProcessor::RDiscount

    context.content = '# header'
    assert_equal("<h1>header</h1>\n", cp.call(context).content)
  end

end
