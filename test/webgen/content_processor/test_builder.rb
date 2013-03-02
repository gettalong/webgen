# -*- encoding: utf-8 -*-

require 'webgen/test_helper'

class TestBuilder < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_static_call
    require 'webgen/content_processor/builder' rescue skip('Library builder not installed')

    setup_context
    cp = Webgen::ContentProcessor::Builder

    @context.content = "xml.div(:path => context.node.alcn) { xml.strong('test'); " +
      "context.website; context; context.ref_node; context.dest_node }"
    assert_equal("<div path=\"/test\">\n  <strong>test</strong>\n</div>\n", cp.call(@context).content)

    @context.content = "xml.div do \n5+5\n+=+6\nend"
    assert_error_on_line(SyntaxError, 3) { cp.call(@context) }

    @context.content = "xml.div do \n5+5\nunknown\n++6\nend"
    assert_error_on_line(NameError, 3) { cp.call(@context) }
  end

end
