# -*- encoding: utf-8 -*-

require 'fileutils'
require 'tmpdir'
require 'helper'
require 'test/unit'
require 'webgen/websitemanager'

class TestWebsiteManager < Test::Unit::TestCase

  def test_initialize
    wm = Webgen::WebsiteManager.new('.')
    t = wm.bundles['default']
    assert_equal('Thomas Leitner', t.author)
    assert(t.paths.length > 0)
  end

  def test_create_website
    with_tmpdir do |dir|
      wm = Webgen::WebsiteManager.new(dir)
      wm.create_website
      assert(File.directory?(File.join(dir, 'ext')))
      assert(File.directory?(File.join(dir, 'src')))
      assert(File.file?(File.join(dir, 'README')))
      assert(File.file?(File.join(dir, 'config.yaml')))
    end
  end

  def test_apply_bundle
    with_tmpdir do |dir|
      wm = Webgen::WebsiteManager.new(dir)
      assert_raise(RuntimeError) { wm.apply_bundle('default') }

      Dir.mkdir(dir)
      wm.apply_bundle('default')
      assert(File.directory?(File.join(dir, 'src')))
      assert(File.file?(File.join(dir, 'src', 'index.page')))

      assert_raise(ArgumentError) { wm.apply_bundle('unknown-bundle') }

      FileUtils.rm_rf(dir)
      wm.bundles.select {|n,i| n =~ /^style-/}.each do |name, infos|
        Dir.mkdir(dir)
        wm.apply_bundle(name)
        assert(File.directory?(File.join(dir, 'src')))
        assert(File.file?(File.join(dir, 'src', 'default.template')))
        assert(File.file?(File.join(dir, 'src', 'default.css')))
        FileUtils.rm_rf(dir)
      end
    end
  end

  def with_tmpdir
    dir = File.join(Dir.tmpdir, 'webgen-' + Process.pid.to_s)
    yield(dir) if block_given?
    dir
  ensure
    FileUtils.rm_rf(dir)
  end

end
