# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/common'

class TestCommon < Test::Unit::TestCase

  def test_absolute_path
    assert_raise(ArgumentError) { Webgen::Common.absolute_path('test', 'test') }
    assert_equal('/', Webgen::Common.absolute_path('/', '/'))
    assert_equal('/dir', Webgen::Common.absolute_path('/dir', '/other'))
    assert_equal('/other/dir', Webgen::Common.absolute_path('dir', '/other'))
    assert_equal('/test/dir', Webgen::Common.absolute_path('../test/dir', '/other'))
    assert_equal('/', Webgen::Common.absolute_path('/..', '/'))
    assert_equal('/dir', Webgen::Common.absolute_path('/../dir/.', '/'))
  end

end
