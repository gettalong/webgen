# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'helper'
require 'ostruct'
require 'webgen/content_processor/erb'
require 'webgen/context'

class TestBuilder < MiniTest::Unit::TestCase

  include Test::WebgenAssertions

  def test_static_call
    website = MiniTest::Mock.new
    website.expect(:ext, OpenStruct.new)
    node = MiniTest::Mock.new
    node.expect(:alcn, '/test')

    context = Webgen::Context.new(website, :chain => [node], :doit => 'hallo')
    cp = Webgen::ContentProcessor::Erb

    context.content = "<%= context[:doit] %>6\n<%= context.ref_node.alcn %>\n<%= context.node.alcn %>\n<%= context.dest_node.alcn %><% context.website %>"
    assert_equal("hallo6\n/test\n/test\n/test", cp.call(context).content)

    context.content = "\n<%= 5* %>"
    assert_error_on_line(SyntaxError, 2) { cp.call(context) }
  end

end
