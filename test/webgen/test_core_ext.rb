# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/core_ext'

class TestCoreExtensions < MiniTest::Unit::TestCase

  def test_webgen_require
    assert_raises(Webgen::LoadError) { webgen_require('unknown_library_here') }
    webgen_require('webgen/core_ext') rescue flunk
  end

  def test_hash_symbolize_keys!
    h = {'a' => 'a', :b => 'b', 5 => 5}.symbolize_keys
    assert_equal('a', h[:a])
    assert_equal('b', h[:b])
    assert_equal(5, h[5])
  end

end
