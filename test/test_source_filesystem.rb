require 'test/unit'
require 'helper'
require 'webgen/source'
require 'tmpdir'
require 'fileutils'
require 'rbconfig'

class TestSourceFileSystemPath < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_io
    path = Webgen::Source::FileSystem::Path.new('/test.rb', __FILE__)
    assert(path.io.data =~ /TestSourceFileSystemPath/)
  end

  def test_changed?
    path = Webgen::Source::FileSystem::Path.new('/test.rb', __FILE__)
    assert(!path.changed?)
    @website.cache.instance_eval { @old_data[[:fs_path, __FILE__]] = File.mtime(__FILE__) - 1 }
    assert(path.changed?)
    @website.cache.instance_eval { @old_data[[:fs_path, __FILE__]] = File.mtime(__FILE__) + 1 }
    assert(!path.changed?)
  end

end

class TestSourceFileSystem < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @website = Webgen::Website.new(File.join(File.dirname(__FILE__), '..'), nil)
    @website.init
    Thread.current[:webgen_website] = @website
  end

  def test_initialize
    source = Webgen::Source::FileSystem.new('test', '**/*.page')
    assert_equal('**/*.page', source.glob)
    assert_equal(File.join(File.dirname(__FILE__), '..', 'test'), source.root)

    source = Webgen::Source::FileSystem.new('/tmp/hallo')
    assert_equal('**/*', source.glob)
    assert_equal('/tmp/hallo', source.root)

    source = Webgen::Source::FileSystem.new('c:/tmp/hallo')
    assert_equal('c:/tmp/hallo', source.root)

    source = Webgen::Source::FileSystem.new('../hallo')
    assert_equal(File.join(@website.directory, '../hallo'), source.root)
  end

  def test_paths
    source = Webgen::Source::FileSystem.new(File.join(File.dirname(__FILE__), '..', 'lib', 'webgen'), '/source/../**/*')
    assert(source.paths.length > 1)
    assert(source.paths.include?(Webgen::Path.new('/source/')))
    assert(source.paths.include?(Webgen::Path.new('/source/filesystem.rb')))
  end

  def test_handling_of_invalid_link
    return if Config::CONFIG['arch'].include?('mswin32')
    dir = File.join(Dir.tmpdir, 'webgen-link-test')
    FileUtils.mkdir_p(dir)
    FileUtils.touch(File.join(dir, 'test'))
    File.symlink('non-existing-file', File.join(dir, 'invalid-link'))
    source = Webgen::Source::FileSystem.new(dir, '/t*')
    assert(source.paths.length == 1)
  ensure
    FileUtils.rm_rf(dir)
  end

end
