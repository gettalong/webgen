# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'rbconfig'
require 'webgen/source/file_system'

class TestSourceFileSystem < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @root = File.dirname(__FILE__)
    @website.expect(:directory, @root)
  end

  def test_initialize
    source = Webgen::Source::FileSystem.new(@website, 'test', '**/*.page')
    assert_equal('**/*.page', source.glob)
    assert_equal(File.join(@root, 'test'), source.root)

    if Config::CONFIG['host_os'] =~ /mswin|mingw/
      source = Webgen::Source::FileSystem.new(@website, 'c:/tmp/hallo')
      assert_equal('c:/tmp/hallo', source.root)
    else
      source = Webgen::Source::FileSystem.new(@website, '/tmp/hallo')
      assert_equal('**/*', source.glob)
      assert_equal('/tmp/hallo', source.root)
    end
    source = Webgen::Source::FileSystem.new(@website, '../hallo')
    assert_equal(File.expand_path(File.join(@root, '../hallo')), source.root)
  end

  def test_paths
    source = Webgen::Source::FileSystem.new(@website, '.', '/../source/**/*')
    assert(source.paths.length > 1)
    assert(source.paths.include?(Webgen::Path.new('/source/')))
    assert(source.paths.include?(Webgen::Path.new('/source/test_file_system.rb')))
  end

  def test_handling_of_invalid_link
    return if Config::CONFIG['host_os'] =~ /mswin|mingw/
    dir = File.join(Dir.tmpdir, 'webgen-link-test')
    FileUtils.mkdir_p(dir)
    FileUtils.touch(File.join(dir, 'test'))
    File.symlink('non-existing-file', File.join(dir, 'invalid-link'))
    source = Webgen::Source::FileSystem.new(@website, dir, '/t*')
    assert(source.paths.length == 1)
  ensure
    FileUtils.rm_rf(dir) if dir
  end

end
