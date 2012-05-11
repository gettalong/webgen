# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/context'
require 'webgen/tag/date'
require 'time'

class TestTagDate < MiniTest::Unit::TestCase

  def test_call
    website, context = Test.setup_tag_test
    context[:config] = {'tag.date.format' => '%Y%m%d'}

    assert_equal(Time.now.strftime("%Y%m%d"), Webgen::Tag::Date.call('date', '', context))
  end

end
