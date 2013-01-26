# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'set'
require 'webgen/source'
require 'webgen/path'

class Webgen::Source::MySource

  def initialize(website, paths); @paths = paths; end
  def paths; Set.new(@paths); end

end

class TestSource < MiniTest::Unit::TestCase

  def setup
    @website = Object.new
    @src = Webgen::Source.new(@website)
  end

  def test_register
    @src.register('Webgen::Destination::MySource')
    assert(@src.registered?('my_source'))

    @src.register('MySource')
    assert(@src.registered?('my_source'))

    @src.register('MySource', :name => 'test')
    assert(@src.registered?('test'))

    assert_raises(ArgumentError) { @src.register('doit') { "nothing" } }
  end

  def test_paths
    @src.register('Stacked')
    @src.register('MySource')

    path1 = Webgen::Path.new('/path1.file')
    path2 = Webgen::Path.new('/path2.data')
    path3 = Webgen::Path.new('/path3.file')

    @src.passive_sources << ['/', 'my_source', [path2]]
    @website.define_singleton_method(:config) do
      {'sources' => [['/', 'my_source', [path1]], ['/hallo/', 'my_source', [path3]]],
        'sources.ignore_paths' => ['/**/*.data']}
    end

    assert_equal([path1, path3.mount_at('/hallo/')], @src.paths)
  end

end
