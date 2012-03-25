# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/content_processor/haml'

class TestHaml < MiniTest::Unit::TestCase

  include Test::WebgenAssertions

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    cp = Webgen::ContentProcessor::Haml

    context.content = "#content\n  %h1 Hallo\n  = [context.node.alcn, context.ref_node.alcn, context.dest_node.alcn].join"
    assert_equal("<div id='content'>\n  <h1>Hallo</h1>\n  /test/test/test\n</div>\n", cp.call(context).content)

    context.content = "#cont\n    % = + unknown"
    assert_error_on_line(Webgen::RenderError, 2) { cp.call(context) }

    context.content = "#cont\n  = unknown"
    assert_error_on_line(NameError, 2) { cp.call(context) }
  end

end