# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tag/date'
require 'time'

class TestTagDate < Minitest::Test

  include Webgen::TestHelper

  def test_call
    context = setup_context
    time = Time.now
    context[:config] = {'tag.date.format' => '%Y%m%d'}
    context[:chain] = [Webgen::Node.new(@website.tree.dummy_root, '/', '/', 'created_at' => time)]

    assert_equal(Time.now.strftime("%Y%m%d"), Webgen::Tag::Date.call('date', '', context))

    context[:config]['tag.date.mi'] = 'created_at'
    assert_equal(time.strftime("%Y%m%d"), Webgen::Tag::Date.call('date', '', context))
  end

end
