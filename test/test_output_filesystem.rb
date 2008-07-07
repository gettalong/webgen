require 'test/unit'
require 'helper'
require 'webgen/output/filesystem'
require 'tmpdir'
require 'fileutils'

class TestOutputFileSystem < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @website = Webgen::Website.new(File.join(Dir.tmpdir, 'test_webgen'), nil)
    @website.init
    Thread.current[:webgen_website] = @website
  end

  def teardown
    super
    FileUtils.rm_rf(File.join(Dir.tmpdir, 'test_webgen'))
  end

  def test_initialize
    output = Webgen::Output::FileSystem.new('test')
    assert_equal(File.join(@website.directory, 'test'), output.root)
    output = Webgen::Output::FileSystem.new('/tmp/hallo')
    assert_equal('/tmp/hallo', output.root)
    output = Webgen::Output::FileSystem.new('../hallo')
    assert_equal(File.join(@website.directory, '../hallo'), output.root)
  end

  def test_file_methods
    output = Webgen::Output::FileSystem.new('test')
    assert(!output.exists?('/dir/hallo'))

    output.write('/dir/hallo', 'content', :file)
    assert(File.file?(File.join(output.root, 'dir/hallo')))
    assert_equal('content', File.read(File.join(output.root, 'dir/hallo')))
    assert(output.exists?('/dir/hallo'))

    output.delete('/dir/hallo')
    assert(!output.exists?('/dir/hallo'))

    output.write('/dir/hallo', Webgen::Path::SourceIO.new { StringIO.new('content')}, :file)
    assert_equal('content', File.read(File.join(output.root, 'dir/hallo')))
    assert(output.exists?('/dir/hallo'))

    output.delete('/dir')
    assert(!output.exists?('/dir'))

    output.write('/dir', '', :directory)
    assert(File.directory?(File.join(output.root, 'dir')))

    assert_raise(RuntimeError) { output.write('other', '', :unknown) }
  end

end
