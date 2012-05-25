# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/content_processor/ruby'

class TestBuilder < MiniTest::Unit::TestCase

  include Test::WebgenAssertions

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    cp = Webgen::ContentProcessor::Ruby

    context.content = "context.content = context.dest_node.alcn"
    assert_equal(node.alcn, cp.call(context).content)

    context.content = "5+5\n+=+6\n"
    assert_error_on_line(SyntaxError, 2) { cp.call(context) }

    context.content = "5+5\nunknown\n++6"
    assert_error_on_line(NameError, 2) { cp.call(context) }
  end

end
