# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorErb < Test::Unit::TestCase

  def test_call
    obj = Webgen::ContentProcessor::Erb.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    context = Webgen::ContentProcessor::Context.new(:content => '<%= context[:doit] %>6', :doit => 'hallo',
                                                    :chain => [node])
    obj.call(context)
    assert_equal('hallo6', context.content)

    context.content = '<%= 5* %>'
    assert_raise(RuntimeError) { obj.call(context) }
  end

end
