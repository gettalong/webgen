# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/utils'

class TestUtils < Minitest::Test

  def test_class_const_for_name
    assert_equal(Webgen::Utils, Webgen::Utils.const_for_name('Webgen::Utils'))
  end

  def test_class_snake_case
    assert_equal('webgen/html_error_now', Webgen::Utils.snake_case('Webgen::HTMLErrorNow'))
  end

end
