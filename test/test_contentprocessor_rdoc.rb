# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorRDoc < Test::Unit::TestCase

  def test_call
    obj = Webgen::ContentProcessor::RDoc.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    context = Webgen::Context.new(:content => "* hello",
                                                    :chain => [node])
    assert_equal("<ul>\n<li>hello\n\n</li>\n</ul>\n", obj.call(context).content)
  end

end
