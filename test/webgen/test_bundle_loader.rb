# -*- encoding: utf-8 -*-

require 'fileutils'
require 'webgen/test_helper'
require 'webgen/bundle_loader'

class TestBundleLoader < Minitest::Test

  include Webgen::TestHelper

  def setup
    setup_website

    @extdir = File.join(@website.directory, 'ext')
    FileUtils.mkdir_p(File.join(@extdir, 'my_ext'))
    FileUtils.mkdir_p(File.join(@extdir, 'webgen'))
    @webgen_file = File.join(@extdir, 'webgen', 'init.rb')
    FileUtils.touch(@webgen_file)
    @ext_file = File.join(@extdir, 'my_ext', 'init.rb')
    FileUtils.touch(@ext_file)
    @ext_info_file = File.join(@extdir, 'my_ext', 'info.yaml')
    File.write(@ext_info_file, <<EOF)
author: authority
summary: summaries

extensions:
  dummy:
    summary: dummy

options:
  dummy:
    summary: dummy
EOF

    @loader = Webgen::BundleLoader.new(@website, @extdir)
  end

  def teardown
    FileUtils.rm_rf(@website.directory)
  end

  def test_load
    assert_raises(Webgen::BundleLoadError) { @loader.load('unknown') }

    @loader.load('webgen')
    assert_nil(@website.ext.bundle_infos.instance_variable_get(:@infos))
    assert_equal({}, @website.ext.bundle_infos.bundles['webgen'])

    @loader.load('my_ext')
    @loader.load('my_ext')
    assert_equal([File.expand_path(@webgen_file), File.expand_path(@ext_file)], @loader.instance_variable_get(:@loaded))
    assert_equal({}, @website.ext.bundle_infos.bundles['webgen'])
    assert_equal({'author' => 'authority', 'summary' => 'summaries'},
                 @website.ext.bundle_infos.bundles['my_ext'])
    assert_equal({'author' => 'authority', 'bundle' => 'my_ext', 'summary' => 'dummy'},
                 @website.ext.bundle_infos.extensions['dummy'])
    assert_equal({'author' => 'authority', 'bundle' => 'my_ext', 'summary' => 'dummy'},
                 @website.ext.bundle_infos.options['dummy'])
  end

  def test_dsl
    File.write(File.join(@extdir, 'init.rb'), "load('my_ext'); require_relative('webgen/init.rb')")
    File.write(@ext_file, "mount_passive('data', '/test', '*.hallo')")

    @website.ext.source = OpenStruct.new
    @website.ext.source.passive_sources = [['/', :file, 'other']]

    @loader.load('init.rb')
    assert($LOADED_FEATURES.include?(@webgen_file))
    assert_equal([['/test', :file_system, File.expand_path(File.dirname(@ext_file) + '/data'), '*.hallo'],
                  ['/', :file, 'other']], @website.ext.source.passive_sources)
  end

end
