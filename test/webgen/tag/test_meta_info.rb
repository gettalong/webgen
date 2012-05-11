# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/logger'
require 'webgen/context'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/tag/meta_info'
require 'time'

class TestTagMetaInfo < MiniTest::Unit::TestCase

  def test_call
    website, context = Test.setup_tag_test
    website.expect(:tree, Webgen::Tree.new(website))
    website.expect(:logger, Logger.new(StringIO.new))
    node = Webgen::Node.new(website.tree.dummy_root, 'test', 'test', 'lang' => 'en', 'key' => 'value <br />')
    context[:chain] = [node]

    context[:config] = {'tag.meta_info.escape_html' => true}
    assert_equal("en", Webgen::Tag::MetaInfo.call('lang', '', context))
    assert_equal("value &lt;br /&gt;", Webgen::Tag::MetaInfo.call('key', '', context))
    assert_equal("", Webgen::Tag::MetaInfo.call('invalid', '', context))

    context[:config] = {'tag.meta_info.escape_html' => false}
    assert_equal("value <br />", Webgen::Tag::MetaInfo.call('key', '', context))
  end

end
