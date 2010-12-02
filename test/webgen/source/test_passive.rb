# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'set'
require 'webgen/source/passive'

class TestSourcePassive < MiniTest::Unit::TestCase

  def test_paths
    path = MiniTest::Mock.new
    path.expect(:passive=, nil, [true])
    source = MiniTest::Mock.new
    source.expect(:paths, Set.new([path]))
    psource = Webgen::Source::Passive.new(source)

    assert_equal(Set.new([path]), psource.paths)
    source.verify
    path.verify
  end

end
