# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'rbconfig'
require 'webgen/source/file_system'

class TestSourceFileSystem < MiniTest::Unit::TestCase

  def setup
    @root = root = File.expand_path(File.dirname(__FILE__))
    @website = Object.new
    @website.define_singleton_method(:directory) { root }
  end

  def test_initialize
    source = Webgen::Source::FileSystem.new(@website, 'test', '**/*.page')
    assert_equal('**/*.page', source.glob)
    assert_equal(File.join(@root, 'test'), source.root)

    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
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
    skip if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
    Dir.mktmpdir('webgen-link-test') do |dir|
      FileUtils.touch(File.join(dir, 'test'))
      File.symlink('non-existing-file', File.join(dir, 'invalid-link'))
      source = Webgen::Source::FileSystem.new(@website, dir, '/t*')
      assert(source.paths.length == 1)
    end
  end

end
