# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/source/stacked'

class TestSourceStacked < Minitest::Test

  class TestSource
    def initialize(paths); @paths = paths; end
    def paths; Set.new(@paths); end
  end

  def test_initialize
    source = Webgen::Source::Stacked.new(nil)
    assert_equal([], source.stack)
    source = Webgen::Source::Stacked.new(nil, {'/dir' => 6})
    assert_equal([['/dir', 6]], source.stack)
  end

  def test_paths
    path1 = Minitest::Mock.new
    path1.expect(:mount_at, 'path1', ['/'])
    path1.expect(:hash, 'path1'.hash)
    path2 = Minitest::Mock.new
    path2.expect(:mount_at, 'path2', ['/hallo/'])
    path2.expect(:hash, 'path2'.hash)

    source = Webgen::Source::Stacked.new(nil, '/' => TestSource.new([path1]), '/hallo/' => TestSource.new([path2]))
    assert_equal(Set.new(['path1', 'path2']), source.paths)

    path1.verify
    path2.verify
  end

end
