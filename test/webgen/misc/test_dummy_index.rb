# -*- encoding: utf-8 -*-

require 'fileutils'
require 'tmpdir'
require 'webgen/test_helper'
require 'webgen/misc/dummy_index'

class TestMiscDummyIndex < Minitest::Test

  class DummyDestination

    attr_accessor :paths

    def initialize(paths = {})
      @paths = paths
    end

    def exists?(path)
      @paths.has_key?(path)
    end

    def write(path, content)
      @paths[path] = content
    end

  end

  include Webgen::TestHelper

  def setup
    setup_website('misc.dummy_index.enabled' => true, 'misc.dummy_index.directory_indexes' => ['index.html'])
    setup_default_nodes(@website.tree)
    @website.ext.destination = DummyDestination.new('/' => nil, '/dir/' => nil, '/dir/dir/' => nil, '/dir2/' => nil)

    @website.tree['/dir/'].meta_info['proxy_path'] = '../other.html'
    @website.tree['/dir/dir/'].meta_info['proxy_path'] = 'my_other.html'
    @website.tree['/dir2/'].meta_info['proxy_path'] = 'index.html'
    @dummy_index = Webgen::Misc::DummyIndex.new(@website)
  end

  def test_initialize
    @website.blackboard.dispatch_msg(:website_generated)
    refute(@website.ext.destination.paths['/dir/index.html'])

    @website.config['misc.dummy_index.enabled'] = false
    @website.blackboard.dispatch_msg(:website_initialized)
    @website.blackboard.dispatch_msg(:website_generated)
    refute(@website.ext.destination.paths['/dir/index.html'])

    @website.config['misc.dummy_index.enabled'] = true
    @website.config['misc.dummy_index.directory_indexes'] = []
    @website.blackboard.dispatch_msg(:website_initialized)
    @website.blackboard.dispatch_msg(:website_generated)
    refute(@website.ext.destination.paths['/dir/index.html'])

    @website.config['misc.dummy_index.directory_indexes'] = ['index.html']
    @website.blackboard.dispatch_msg(:website_initialized)
    @website.blackboard.dispatch_msg(:website_generated)
    assert(@website.ext.destination.paths['/dir/index.html'])
  end

  def test_create_dummy_indexes
    paths = @website.ext.destination.paths

    # without cache
    @dummy_index.send(:create_dummy_indexes)
    assert_match(/url=\.\.\/other.html"/, paths['/dir/index.html'])
    assert_match(/url=my_other.html"/, paths['/dir/dir/index.html'])
    refute(paths['/dir2/index.html'])

    # with cache and destination paths exist
    @logio.string = ''
    @dummy_index.send(:create_dummy_indexes)
    assert_log_match(/\A\z/)

    # with cache, one destination path does not exist
    paths.delete('/dir/index.html')
    @dummy_index.send(:create_dummy_indexes)
    assert(paths['/dir/index.html'])
    assert_log_match(/\A.*\Z/)
  end

end
