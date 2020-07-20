# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/ruby'

class TestContentProcessorRuby < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    setup_context
    cp = Webgen::ContentProcessor::Ruby

    @context.content = "context.content = context.dest_node.alcn"
    assert_equal(@context.dest_node.alcn, cp.call(@context).content)

    @context.content = "x = 5+5\n+=+6\n"
    assert_error_on_line(SyntaxError, 2) { cp.call(@context) }

    @context.content = "x = 5+5\nunknown\n++6"
    assert_error_on_line(NameError, 2) { cp.call(@context) }
  end

end
