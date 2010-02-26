# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'
require 'webgen/tag'

class TestTagMetainfo < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_call
    @obj = Webgen::Tag::Metainfo.new
    node = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'hallo.page', 'hallo.page', 'test' => 10, 'lang' => 'en',
                            'bad' => 'Something <&>" Bad')
    c = Webgen::Context.new(:chain => [node])
    assert_equal('', @obj.call('invalid', '', c))
    assert_equal('10', @obj.call('test', '', c))
    assert_equal('en', @obj.call('lang', '', c))
    assert_equal('Something &lt;&amp;&gt;&quot; Bad', @obj.call('bad', '', c))
    @obj.set_params('tag.metainfo.escape_html' => false)
    assert_equal('Something <&>" Bad', @obj.call('bad', '', c))
  end

end
