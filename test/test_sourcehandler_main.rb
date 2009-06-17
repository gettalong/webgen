# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/website'
require 'tmpdir'
require 'fileutils'

class TestSourceHandlerMain < Test::Unit::TestCase

  def test_output_deletion
    dir = nil
    setup_task = lambda do
      dir = File.join(Dir.tmpdir, 'webgen-' + Process.pid.to_s)
      FileUtils.rm_rf(dir)
      FileUtils.mkdir_p(dir)
      FileUtils.mkdir_p(File.join(dir, 'src'))
      FileUtils.touch(File.join(dir, 'src', 'test.jpg'))
    end

    setup_task.call
    ws = Webgen::Website.new(dir, nil) {|c| c['output.do_deletion'] = false }
    assert_equal(:success, ws.render)
    assert(File.exists?(File.join(dir, 'out', 'test.jpg')))
    FileUtils.rm_rf(File.join(dir, 'src', 'test.jpg'))
    assert_equal(:success, ws.render)
    assert(File.exists?(File.join(dir, 'out', 'test.jpg')))

    setup_task.call
    ws = Webgen::Website.new(dir, nil) {|c| c['output.do_deletion'] = true }
    assert_equal(:success, ws.render)
    assert(File.exists?(File.join(dir, 'out', 'test.jpg')))
    FileUtils.rm_rf(File.join(dir, 'src', 'test.jpg'))
    assert_equal(:success, ws.render)
    assert(!File.exists?(File.join(dir, 'out', 'test.jpg')))
  ensure
    FileUtils.rm_rf(dir)
  end

end
