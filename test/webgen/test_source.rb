# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'set'
require 'webgen/source'

class Webgen::Source::MySource

  def initialize(website, paths); @paths = paths; end
  def paths; Set.new(@paths); end

end

class TestSource < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
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

    path1 = MiniTest::Mock.new
    path1.expect(:mount_at, path1, ['/'])
    path1.expect(:to_str, 'path1.file')
    path1.expect(:=~, false, [/\/$/])
    path1.expect(:hash, 'path1.file'.hash)
    path2 = MiniTest::Mock.new
    path2.expect(:mount_at, path2, ['/'])
    path2.expect(:to_str, 'path2.data')
    path2.expect(:=~, false, [/\/$/])
    path2.expect(:[]=, nil, ['passive', true])
    path2.expect(:hash, 'path2.data'.hash)
    path3 = MiniTest::Mock.new
    path3.expect(:mount_at, path3, ['/hallo/'])
    path3.expect(:to_str, 'path3.file')
    path3.expect(:=~, false, [/\/$/])
    path3.expect(:hash, 'path3.file'.hash)

    @src.passive_sources << ['/', 'my_source', [path2]]
    @website.expect(:config, {'sources' => [['/', 'my_source', [path1, path2]], ['/hallo/', 'my_source', [path3]]],
                      'sources.ignore_paths' => ['**.data']})
    assert_equal([path1, path3], @src.paths)
    [@website, path1, path2, path3].each {|m| m.verify}
  end

end
