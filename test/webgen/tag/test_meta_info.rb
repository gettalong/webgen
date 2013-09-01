# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tag/meta_info'
require 'time'

class TestTagMetaInfo < Minitest::Test

  include Webgen::TestHelper

  def test_call
    setup_context
    node = Webgen::Node.new(@website.tree.dummy_root, 'test', 'test', 'lang' => 'en', 'key' => 'value <br />')
    @context[:chain] = [node]

    @context[:config] = {'tag.meta_info.escape_html' => true}
    assert_equal("en", Webgen::Tag::MetaInfo.call('lang', '', @context))
    assert_equal("value &lt;br /&gt;", Webgen::Tag::MetaInfo.call('key', '', @context))
    assert_equal("", Webgen::Tag::MetaInfo.call('invalid', '', @context))

    @context[:config] = {'tag.meta_info.escape_html' => false}
    assert_equal("value <br />", Webgen::Tag::MetaInfo.call('key', '', @context))

    @context[:config] = {'tag.meta_info.mi' => 'key'}
    assert_equal("value <br />", Webgen::Tag::MetaInfo.call('meta_info', '', @context))
  end

end
