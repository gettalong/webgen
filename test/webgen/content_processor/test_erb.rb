# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/erb'

class TestErb < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    setup_context
    cp = Webgen::ContentProcessor::Erb

    @context.content = "<%= context[:doit] %>6\n<%= context.ref_node.alcn %>\n<%= context.node.alcn %>\n<%= context.dest_node.alcn %><% context.website %>"
    assert_equal("hallo6\n/test\n/test\n/test", cp.call(@context).content)

    @website.config['content_processor.erb.trim_mode'] = '%'
    @context.content = "% 3.times do\na\n% end"
    assert_equal("a\na\na\n", cp.call(@context).content)

    @context.content = "\n<%= 5* %>"
    assert_error_on_line(SyntaxError, 2) { cp.call(@context) }
  end

end
