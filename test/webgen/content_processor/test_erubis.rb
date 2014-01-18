# -*- encoding: utf-8 -*-

require 'webgen/test_helper'

class TestErubis < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    require 'webgen/content_processor/erubis' rescue skip('Library erubis not installed')
    setup_context
    @website.config.merge!('content_processor.erubis.options' => {}, 'content_processor.erubis.use_pi' => false)
    cp = Webgen::ContentProcessor::Erubis

    @context.content = "<%= context[:doit] %>6\n<%= h(context.ref_node.alcn) %>\n<%= context.node.alcn %>\n<%= context.dest_node.alcn %><% context.website %>"
    assert_equal("hallo6\n/test\n/test\n/test", cp.call(@context).content)

    @context.content = "\n<%= 5* %>"
    assert_error_on_line(SyntaxError, 2) { cp.call(@context) }

    @context.content = "\n\n<% unknown %>"
    assert_error_on_line(NameError, 3) { cp.call(@context) }

    @website.config['content_processor.erubis.options'][:trim] = true
    @context.content = "<% for i in [1] %>\n<%= i %>\n<% end %>"
    assert_equal("1\n", cp.call(@context).content)

    @website.config['content_processor.erubis.use_pi'] = true
    @context.content = "<?rb for i in [1] ?>\n@{i}@\n<?rb end ?>"
    assert_equal("1\n", cp.call(@context).content)
  end

end
