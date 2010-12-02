# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'set'
require 'webgen/source'

class Webgen::Source::MySource

  def initialize(paths); @paths = paths; end
  def paths; Set.new(@paths); end

end

class TestSource < MiniTest::Unit::TestCase

  def setup
    @src = Webgen::Source.new
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
    @src = Webgen::Source.static.clone
    @src.register('MySource')
    website = MiniTest::Mock.new
    @src.website = website

    path1 = MiniTest::Mock.new
    path1.expect(:mount_at, path1, ['/'])
    path1.expect(:to_str, 'path1.file')
    path1.expect(:source_path, 'path1')
    path2 = MiniTest::Mock.new
    path2.expect(:mount_at, path2, ['/'])
    path2.expect(:to_str, 'path2.data')
    path2.expect(:passive=, nil, [true])
    path3 = MiniTest::Mock.new
    path3.expect(:mount_at, path3, ['/hallo/'])
    path3.expect(:to_str, 'path3.file')
    path3.expect(:source_path, 'path3')

    website.expect(:config, {'sources' => [['/', 'my_source', [path1, path2]], ['/hallo/', 'my_source', [path3]]],
                     'sources.passive' => [['/', 'my_source', [path2]]],
                     'sources.ignore' => ['**.data']})
    expected = {'path1' => path1, 'path3' => path3}
    assert_equal(expected, @src.paths)
    [website, path1, path2, path3].each {|m| m.verify}
  end

end
