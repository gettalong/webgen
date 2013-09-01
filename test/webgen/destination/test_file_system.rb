# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/destination/file_system'
require 'webgen/path'

class TestDestinationFileSystem < Minitest::Test

  def setup
    @dir = dir = Dir.mktmpdir('test-webgen')
    @website = Object.new
    @website.define_singleton_method(:directory) { dir }
  end

  def teardown
    FileUtils.remove_entry_secure(@dir)
  end

  def test_initialize
    dest = Webgen::Destination::FileSystem.new(@website, 'test')
    assert_equal(File.join(@dir, 'test'), dest.root)
    dest = Webgen::Destination::FileSystem.new(@website, '/tmp/hallo')
    assert_equal(File.absolute_path('/tmp/hallo', @website.directory), dest.root)
    dest = Webgen::Destination::FileSystem.new(@website, '../hallo')
    assert_equal(File.expand_path(File.join(@dir, '../hallo')), dest.root)
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
    assert_equal('contentö', dest.read('/dir/hallo', 'r:UTF-8'))
    assert_equal('contentö', File.read(File.join(dest.root, 'dir/hallo'), :mode => 'r:UTF-8'))

    dest.delete('/dir')
    refute(dest.exists?('/dir'))

    dest.write('/dir/', '')
    assert(File.directory?(File.join(dest.root, 'dir')))
  end

end
