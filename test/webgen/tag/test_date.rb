# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tag/date'
require 'time'

class TestTagDate < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_call
    context = setup_context
    context[:config] = {'tag.date.format' => '%Y%m%d'}

    assert_equal(Time.now.strftime("%Y%m%d"), Webgen::Tag::Date.call('date', '', context))
  end

end
