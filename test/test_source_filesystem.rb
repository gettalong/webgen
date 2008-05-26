require 'test/unit'
require 'helper'
require 'webgen/source/filesystem'

class TestSourceFileSystemPath < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_io
    path = Webgen::Source::FileSystem::Path.new('/test.rb', __FILE__)
    assert(path.io.data =~ /TestSourceFileSystemPath/)
  end

  def test_changed?
    path = Webgen::Source::FileSystem::Path.new('/test.rb', __FILE__)
    assert(path.changed?)
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
    @website.config['website.dir'] = File.join(File.dirname(__FILE__), '..')
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
  end

  def test_paths
    source = Webgen::Source::FileSystem.new('lib/webgen', '**/*')
    assert(source.paths.length > 1)
    assert(source.paths.include?(Webgen::Path.new('/source/')))
    assert(source.paths.include?(Webgen::Path.new('/source/filesystem.rb')))
  end

end
