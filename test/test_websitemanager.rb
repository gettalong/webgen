require 'fileutils'
require 'tmpdir'
require 'helper'
require 'test/unit'
require 'webgen/websitemanager'

class TestWebsiteManager < Test::Unit::TestCase

  def test_initialize
    wm = Webgen::WebsiteManager.new('.')
    t = wm.templates['default']
    assert_equal('Thomas Leitner', t.author)
    assert(t.paths.length > 0)

    s = wm.styles['1024px']
    assert(s.paths.length > 0)
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

  def test_apply_template
    with_tmpdir do |dir|
      wm = Webgen::WebsiteManager.new(dir)
      assert_raise(RuntimeError) { wm.apply_template('default') }

      Dir.mkdir(dir)
      wm.apply_template('default')
      assert(File.directory?(File.join(dir, 'src')))
      assert(File.file?(File.join(dir, 'src', 'index.page')))

      assert_raise(ArgumentError) { wm.apply_template('unknown-template') }
    end
  end

  def test_apply_style
    dir = with_tmpdir
    wm = Webgen::WebsiteManager.new(dir)
    assert_raise(RuntimeError) { wm.apply_style('simple') }

    wm.styles.each do |name, infos|
      Dir.mkdir(dir)
      wm.apply_style(name)
      assert(File.directory?(File.join(dir, 'src')))
      assert(File.file?(File.join(dir, 'src', 'default.template')))
      assert(File.file?(File.join(dir, 'src', 'default.css')))
      FileUtils.rm_rf(dir)
    end
    assert_raise(ArgumentError) { wm.apply_style('unknown-style') }
  end

  def with_tmpdir
    dir = File.join(Dir.tmpdir, 'webgen-' + Process.pid.to_s)
    yield(dir) if block_given?
    dir
  ensure
    FileUtils.rm_rf(dir)
  end

end
