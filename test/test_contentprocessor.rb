# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/contentprocessor'

class TestContentProcessor < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @website.config.data['contentprocessor.map'] = {'test' => Hash, 'binary' => [Hash, :binary]}
  end

  def test_access_hash
    ah = Webgen::ContentProcessor::AccessHash.new
    assert(ah.has_key?('test'))
    assert(!ah.has_key?('other'))
    assert_kind_of(Hash, ah['test'])
    assert_nil(ah['other'])
  end

  def test_list
    assert_equal(['binary', 'test'], Webgen::ContentProcessor.list.sort)
  end

  def test_for_name
    assert_kind_of(Hash, Webgen::ContentProcessor.for_name('test'))
    assert_kind_of(Hash, Webgen::ContentProcessor.for_name('binary'))
    assert_nil(Webgen::ContentProcessor.for_name('other'))
  end

  def test_is_binary
    assert(!Webgen::ContentProcessor.is_binary?('test'))
    assert(Webgen::ContentProcessor.is_binary?('binary'))
  end

end
