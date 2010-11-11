# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/coreext'

class TestCoreExtensions < MiniTest::Unit::TestCase

  def test_array_to_hash
    assert_equal({x: 5, y: 6}, [[:x, 5], [:y, 6]].to_hash)
  end

  def test_webgen_require
    assert_raises(Webgen::LoadError) { webgen_require('unknown_library_here') }
    webgen_require('webgen/coreext') rescue flunk
  end

end
