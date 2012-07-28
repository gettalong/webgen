# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/destination/file_system'
require 'webgen/path'

class TestDestinationFileSystem < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @dir = Dir.mktmpdir('test-webgen')
    @website.expect(:directory, @dir)
  end

  def teardown
    FileUtils.remove_entry_secure(@dir)
  end

  def test_initialize
    dest = Webgen::Destination::FileSystem.new(@website, 'test')
    assert_equal(File.join(@dir, 'test'), dest.root)
    dest = Webgen::Destination::FileSystem.new(@website, '/tmp/hallo')
    assert_equal('/tmp/hallo', dest.root)
    dest = Webgen::Destination::FileSystem.new(@website, '../hallo')
    assert_equal(File.expand_path(File.join(@dir, '../hallo')), dest.root)
    @website.verify
  end

  def test_file_methods
    dest = Webgen::Destination::FileSystem.new(@website, 'test')
    assert(!dest.exists?('/dir/hallo'))

    dest.write('/dir/hallo', 'content')
    assert(File.file?(File.join(dest.root, 'dir/hallo')))
    assert(dest.exists?('/dir/hallo'))
    assert_equal('content', File.read(File.join(dest.root, 'dir/hallo')))
    assert_equal('content', dest.read('/dir/hallo'))

    dest.delete('/dir/hallo')
    refute(dest.exists?('/dir/hallo'))

    dest.write('/dir/hallo', Webgen::Path.new('fu') { StringIO.new("contentö")})
    assert(dest.exists?('/dir/hallo'))
    assert_equal('contentö', dest.read('/dir/hallo', 'r'))
    assert_equal('contentö', File.read(File.join(dest.root, 'dir/hallo')))

    dest.delete('/dir')
    refute(dest.exists?('/dir'))

    dest.write('/dir/', '')
    assert(File.directory?(File.join(dest.root, 'dir')))
  end

end
