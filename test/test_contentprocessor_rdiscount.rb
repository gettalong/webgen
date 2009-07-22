# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorRDiscount < Test::Unit::TestCase

  def test_call
    @obj = Webgen::ContentProcessor::RDiscount.new
    node = Webgen::Node.new(Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/'), 'test', 'test')
    context = Webgen::Context.new(:content => '# header', :chain => [node])
    assert_equal("<h1>header</h1>\n", @obj.call(context).content)

    def @obj.require(lib); raise LoadError; end
    assert_raise(Webgen::LoadError) { @obj.call(context) }
  end

end
