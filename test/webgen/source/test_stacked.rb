# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/source/stacked'

class TestSourceStacked < MiniTest::Unit::TestCase

  class TestSource
    def initialize(paths); @paths = paths; end
    def paths; Set.new(@paths); end
  end

  def test_initialize
    source = Webgen::Source::Stacked.new
    assert_equal([], source.stack)
    source = Webgen::Source::Stacked.new({'/dir' => 6})
    assert_equal([['/dir', 6]], source.stack)
  end

  def test_add
    source = Webgen::Source::Stacked.new
    assert_raises(RuntimeError) { source.add(['dir', 6]) }

    source.add('/temp/' => :test)
    assert_equal([['/temp/', :test]], source.stack)
  end

  def test_paths
    source = Webgen::Source::Stacked.new
    path1 = MiniTest::Mock.new
    path1.expect(:mount_at, 'path1', ['/'])
    path2 = MiniTest::Mock.new
    path2.expect(:mount_at, 'path2', ['/hallo/'])

    source.add('/' => TestSource.new([path1]))
    assert_equal(Set.new(['path1']), source.paths)

    source.add('/hallo/' => TestSource.new([path2]))
    assert_equal(Set.new(['path1', 'path2']), source.paths)

    path1.verify
    path2.verify
  end

end
