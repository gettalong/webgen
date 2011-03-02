# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/common'

class TestCommon < MiniTest::Unit::TestCase

  def test_class_const_for_name
    assert_equal Webgen::Common, Webgen::Common.const_for_name('Webgen::Common')
  end

  def test_class_snake_case
    assert_equal('webgen/html_error_now', Webgen::Common.snake_case('Webgen::HTMLErrorNow'))
  end

end
