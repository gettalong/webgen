# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/source'

class TestSourceTarArchive < Test::Unit::TestCase

  class FakeStream

    def open
      require 'stringio'
      sio = StringIO.new
      stream = Archive::Tar::Minitar::Writer.new(sio)
      stream.mkdir('/test', :mtime => (Time.now - 5).to_i, :mode => 0100755)
      stream.add_file('/test/hallo.page', :mtime => (Time.now - 4).to_i, :mode => 0100644) do |os, opts|
        os.write('This is the contents!')
      end
      sio.rewind
      sio
    end

  end

  include Test::WebsiteHelper

  def setup
    super
    @website = Webgen::Website.new(File.join(File.dirname(__FILE__), '..'), nil)
    @website.init
    Thread.current[:webgen_website] = @website
    @stream = FakeStream.new
  end

  def test_initialize
    source = Webgen::Source::TarArchive.new(@stream)
    assert_equal(@stream, source.uri)
  end

  def test_paths
    source = Webgen::Source::TarArchive.new(@stream)
    assert(source.paths.length == 2)
    assert(source.paths.include?(Webgen::Path.new('/test/')))
    assert(source.paths.include?(Webgen::Path.new('/test/hallo.page')))
    assert('This is the contents!', source.paths.first {|p| p.path == '/test/hallo.page'}.io.data)
  end

  def test_path_changed?
    stream = @stream
    source = Webgen::Source::TarArchive.new(stream)
    source.paths.each do |path|
      assert(!path.changed?)
      @website.cache.instance_eval { @old_data[[:tararchive_path, stream, path.path]] = Time.now - 60 }
      assert(path.changed?)
    end
  end

end
