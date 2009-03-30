# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorErb < Test::Unit::TestCase

  def test_call
    obj = Webgen::ContentProcessor::Erb.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    content = "<%= context[:doit] %>6\n<%= ref_node.absolute_lcn %>\n<%= node.absolute_lcn %>\n<%= dest_node.absolute_lcn %><% website %>"
    context = Webgen::ContentProcessor::Context.new(:content => content, :doit => 'hallo',
                                                    :chain => [node])
    obj.call(context)
    assert_equal("hallo6\n/test\n/test\n/test", context.content)

    context.content = '<%= 5* %>'
    assert_raise(RuntimeError) { obj.call(context) }
  end

end
