# -*- encoding: utf-8 -*-

require 'ostruct'
require 'helper'
require 'test/unit'
require 'webgen/tree'
require 'webgen/page'
require 'webgen/contentprocessor'

class TestContentProcessorErubis < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_call
    obj = Webgen::ContentProcessor::Erubis.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    context = Webgen::Context.new(:doit => 'hallo', :chain => [node])

    context.content = "<%= context[:doit] %>6\n<%= context.ref_node.alcn %>\n<%= context.node.alcn %>\n<%= context.dest_node.alcn %><% context.website %>"
    assert_equal("hallo6\n/test\n/test\n/test", obj.call(context).content)

    context.content = "\n<%= 5* %>"
    assert_error_on_line(Webgen::RenderError, 2) { obj.call(context) }

    context.content = "\n\n<% unknown %>"
    assert_error_on_line(Webgen::RenderError, 3) { obj.call(context) }

    context.content = "<% for i in [1] %>\n<%= i %>\n<% end %>"
    assert_equal("1\n", obj.call(context).content)
    @website.config['contentprocessor.erubis.options'][:trim] = false
    context.content = "<% for i in [1] %>\n<%== i %>\n<% end %>"
    assert_equal("\n1\n", obj.call(context).content)

    context[:block] = OpenStruct.new
    context[:block].options = {'erubis_trim' => true}
    context.content = "<% for i in [1] %>\n<%== i %>\n<% end %>"
    assert_equal("1\n", obj.call(context).content)
    context[:block].options['erubis_use_pi'] = true
    context.content = "<?rb for i in [1] ?>\n@{i}@\n<?rb end ?>"
    assert_equal("1\n", obj.call(context).content)
    context[:block] = nil

    @website.config['contentprocessor.erubis.use_pi'] = true
    context.content = "<?rb for i in [1] ?>\n@{i}@\n<?rb end ?>"
    assert_equal("1\n", obj.call(context).content)

    page = Webgen::Page.from_data("--- pipeline:erubis erubis_trim:false erubis_use_pi:false\n<% for i in [1] %>\n<%== i %>\n<% end %>")
    assert_equal("\n1\n", page.blocks['content'].render(context).content)

    def obj.require(lib); raise LoadError; end
    assert_raise(Webgen::LoadError) { obj.call(context) }
  end

end
