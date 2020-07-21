# -*- encoding: utf-8 -*-

require 'webgen/test_helper'

class TestHaml < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    require 'webgen/content_processor/haml' rescue skip('Library haml not installed')
    setup_context
    cp = Webgen::ContentProcessor::Haml

    @context.content = "#content\n  %h1 Hallo\n  = [context.node.alcn, context.ref_node.alcn, context.dest_node.alcn].join"
    assert_equal("<div id='content'>\n<h1>Hallo</h1>\n/test/test/test\n</div>\n", cp.call(@context).content)

    @context.content = "#cont\n    % = + unknown"
    assert_error_on_line(Webgen::RenderError, 2) { cp.call(@context) }

    @context.content = "#cont\n  = unknown"
    assert_error_on_line(NameError, 2) { cp.call(@context) }
  end

end
