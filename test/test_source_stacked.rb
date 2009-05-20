# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/source'

class TestSourceFileSystemStacked < Test::Unit::TestCase

  class TestSource
    def initialize(paths); @paths = paths; end
    def paths; Set.new(@paths); end
  end

  def test_initialize
    source = Webgen::Source::Stacked.new
    assert_equal([], source.stack)
    assert_equal(false, source.cache_paths)
    source = Webgen::Source::Stacked.new({'/dir' => 6}, true)
    assert_equal([['/dir', 6]], source.stack)
    assert_equal(true, source.cache_paths)
  end

  def test_add
    source = Webgen::Source::Stacked.new
    assert_raise(RuntimeError) { source.add(['dir', 6]) }

    test_source = TestSource.new([Webgen::Path.new('/temp')])
    source.add('/temp' => test_source)
    assert_equal([['/temp', test_source]], source.stack)

    source.cache_paths = true
    source.add('/dir' => test_source)
    source.paths
    assert_raise(RuntimeError) { source.add('/dir1' => test_source) }
  end

  def test_paths
    source = Webgen::Source::Stacked.new
    source.add('/' => TestSource.new([Webgen::Path.new('/hallo/dir'), Webgen::Path.new('/other')]))
    source.add('/hallo' => TestSource.new([Webgen::Path.new('/dir'), Webgen::Path.new('/other')]))
    assert_equal(Set.new([Webgen::Path.new('/hallo/dir'), Webgen::Path.new('/other'),
                          Webgen::Path.new('/hallo/other')]), source.paths)

    source.cache_paths = true
    set = source.paths
    assert_equal(set.object_id, source.paths.object_id)
  end

end
