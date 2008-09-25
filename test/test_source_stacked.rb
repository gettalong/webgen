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
    source = Webgen::Source::Stacked.new('/dir' => 6)
    assert_equal([['/dir', 6]], source.stack)
  end

  def test_add
    source = Webgen::Source::Stacked.new
    assert_raise(RuntimeError) { source.add(['dir', 6])}
    source.add('/temp' => :source)
    assert_equal([['/temp', :source]], source.stack)
  end

  def test_paths
    source = Webgen::Source::Stacked.new
    source.add('/' => TestSource.new([Webgen::Path.new('/hallo/dir'), Webgen::Path.new('/other')]))
    source.add('/hallo' => TestSource.new([Webgen::Path.new('/dir'), Webgen::Path.new('/other')]))
    assert_equal(Set.new([Webgen::Path.new('/hallo/dir'), Webgen::Path.new('/other'),
                          Webgen::Path.new('/hallo/other')]), source.paths)
  end

end
