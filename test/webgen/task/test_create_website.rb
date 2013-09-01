# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/task/create_website'
require 'fileutils'
require 'ostruct'

class TestTaskCreateWebsite < Minitest::Test

  include Webgen::TestHelper

  def setup
    setup_website
    @website.ext.task = @task = Webgen::Task.new(@website)
    @task.register('CreateWebsite', :data => {:templates => {}})
  end

  def teardown
    FileUtils.remove_entry_secure(@website.directory) if Dir.exist?(@website.directory)
  end

  def test_static_call
    @task.execute(:create_website)
    assert(File.directory?(@website.directory))
    assert(File.directory?(File.join(@website.directory, 'src')))
    assert(File.file?(File.join(@website.directory, 'webgen.config')))

    assert_raises(Webgen::Task::CreateWebsite::Error) { @task.execute(:create_website) }
  end

  def test_static_call_with_template
    Dir.mktmpdir do |tmpdir|
      Dir.mkdir(File.join(tmpdir, 'tmp'))
      File.open(File.join(tmpdir, 'tmp', 'test.erb.txt'), 'w+') {|f| f.write("<%= '#{tmpdir}' %>")}
      @task.data(:create_website)[:templates]['my_template'] = tmpdir

      @task.execute(:create_website, 'my_template')
      assert(File.directory?(@website.directory))
      assert(File.directory?(File.join(@website.directory, 'tmp')))
      assert_equal(tmpdir, File.read(File.join(@website.directory, 'tmp', 'test.txt')))
      assert(File.directory?(File.join(@website.directory, 'src')))
      assert(File.file?(File.join(@website.directory, 'webgen.config')))
    end
  end

end
