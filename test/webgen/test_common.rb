# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/common'

class TestCommon < MiniTest::Unit::TestCase

  def test_class_const_for_name
    assert_equal Webgen::Common, Webgen::Common.const_for_name('Webgen::Common')
  end

end
