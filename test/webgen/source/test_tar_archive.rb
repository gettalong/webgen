# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'fileutils'
require 'rbconfig'

class TestSourceTarArchive < Minitest::Test

  class FakeStream

    def open
      require 'stringio'
      sio = StringIO.new
      stream = Archive::Tar::Minitar::Writer.new(sio)
      stream.mkdir('/test', :mtime => (Time.now - 5).to_i, :mode => 0100755)
      stream.add_file('/test/hallo.page', :mtime => (Time.now - 4).to_i, :mode => 0100644) do |os, opts|
        os.write('This is the contents!')
      end
      stream.add_file('/other.page', :mtime => (Time.now - 4).to_i, :mode => 0100644) do |os, opts|
        os.write('This is other content!')
      end
      stream.add_file('hallo.page', :mtime => (Time.now - 4).to_i, :mode => 0100644) do |os, opts|
        os.write('This is the hallo.page!')
      end
      sio.rewind
      sio
    end

  end

  def setup
    require 'webgen/source/tar_archive' rescue skip('Library archive-tar-minitar not installed')
    @stream = FakeStream.new
  end

  def test_initialize
    source = Webgen::Source::TarArchive.new(nil, 'http://example.com/test.tar.gz')
    assert_equal('http://example.com/test.tar.gz', source.uri)
  end

  def test_paths
    source = Webgen::Source::TarArchive.new(nil, @stream)
    assert_equal(4, source.paths.length)
    assert(source.paths.include?(Webgen::Path.new('/test/')))
    assert(source.paths.include?(Webgen::Path.new('/test/hallo.page')))
    assert(source.paths.include?(Webgen::Path.new('/hallo.page')))
    assert_equal('This is the contents!', source.paths.find {|p| p.path == '/test/hallo.page'}.data)

    source = Webgen::Source::TarArchive.new(nil, @stream, '/test/*')
    assert_equal(1, source.paths.length)
    assert(source.paths.include?(Webgen::Path.new('/test/hallo.page')))
  end

end
