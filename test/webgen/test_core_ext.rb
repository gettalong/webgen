# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/core_ext'

class TestCoreExtensions < MiniTest::Unit::TestCase

  def test_webgen_require
    assert_raises(Webgen::LoadError) { webgen_require('unknown_library_here') }
    webgen_require('webgen/core_ext') rescue flunk
  end

end
