# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/common'

class TestCommon < MiniTest::Unit::TestCase

  def test_class_const_for_name
    assert_equal Webgen::Common, Webgen::Common.const_for_name('Webgen::Common')
  end

  def test_class_error_line
    begin
      eval("5 =")
    rescue SyntaxError => e
      assert_equal 1, Webgen::Common.error_line(e)
    end

    begin
      eval("x = 5\n raise 'hallo'", binding, __FILE__, 1)
    rescue
      assert_equal 2, Webgen::Common.error_line($!)
    end
  end

end
