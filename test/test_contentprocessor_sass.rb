# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorSass < Test::Unit::TestCase

  def test_call
    obj = Webgen::ContentProcessor::Sass.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    context = Webgen::Context.new(:content => "#main\n  :background-color #000",
                                                    :chain => [node])
    obj.call(context)
    assert_equal("#main {\n  background-color: #000; }\n", context.content)

    context.content = "#cont \n = unknown"
    assert_raise(RuntimeError) { obj.call(context) }
  end

end
