# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'
require 'webgen/tag'

class TestTagMetainfo < Test::Unit::TestCase

  def test_call
    @obj = Webgen::Tag::Metainfo.new
    node = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'hallo.page', 'hallo.page', 'test' => 10, 'lang' => 'en')
    c = Webgen::Context.new(:chain => [node])
    assert_equal('', @obj.call('invalid', '', c))
    assert_equal('10', @obj.call('test', '', c))
    assert_equal('en', @obj.call('lang', '', c))
  end

end
