# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/contentprocessor'
require 'webgen/tag'
require 'time'

class TestTagDate < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_call
    @obj = Webgen::Tag::Date.new
    assert_not_nil(Time.parse(@obj.call('date', '', Webgen::Context.new)))
  end

end
