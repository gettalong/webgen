# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorMaruku < Test::Unit::TestCase

  def test_call
    @obj = Webgen::ContentProcessor::Maruku.new
    node = Webgen::Node.new(Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/'), 'test', 'test')
    context = Webgen::Context.new(:content => '# header', :chain => [node])
    assert_equal('<h1 id=\'header\'>header</h1>', @obj.call(context).content)

    context.content = "# head*d* {#das .dsaf "
    assert_raise(RuntimeError) { @obj.call(context)}
  end

  def test_call_fix_for_invalid_id
    @obj = Webgen::ContentProcessor::Maruku.new
    context = Webgen::Context.new(:content => '# `test`')
    assert_equal('<h1 id=\'id1\'><code>test</code></h1>', @obj.call(context).content)

    context = Webgen::Context.new(:content => '# `test`')
    assert_equal('<h1 id=\'id1\'><code>test</code></h1>', @obj.call(context).content)
  end

end
