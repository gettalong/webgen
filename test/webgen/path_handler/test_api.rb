# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/api'

class TestPathHandlerApi < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def setup
    setup_website('website.lang' => 'en')

    @api = Webgen::PathHandler::Api.new(@website)

    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')

    @path = Webgen::Path.new('/test.api', 'dest_path' => '<parent><basename><ext>',
                             'api_name' => 'my_api',
                             'dir_name' => 'my_dir',
                             'prefix_for_link_defs' => true,
                             'rdoc_options' => ['-t', 'Title', __FILE__])
  end

  def teardown
    FileUtils.rm_rf(@website.directory)
  end

  def test_create_nodes
    @website.ext.path_handler = Webgen::PathHandler.new(@website)
    @website.ext.path_handler.register('Directory')
    @website.ext.path_handler.register('Page')
    @website.ext.path_handler.register('Copy')
    @website.ext.link_definitions = {}
    @api.create_nodes(@path, nil)

    assert(@website.tree['/my_dir/TestPathHandlerApi.en.html'])
    assert_equal(['/my_dir/TestPathHandlerApi.en.html', 'TestPathHandlerApi'],
                 @website.ext.link_definitions['my_api:TestPathHandlerApi'])
    assert(@website.tree['/my_dir/TestPathHandlerApi.en.html#method-i-setup'])
    assert_equal(['/my_dir/TestPathHandlerApi.en.html#method-i-setup', 'TestPathHandlerApi#setup'],
                 @website.ext.link_definitions['my_api:TestPathHandlerApi#setup'])

    cache_dir = @website.tmpdir(File.join('path_handler.api', 'my_api'))
    assert(File.directory?(cache_dir))
  end

  def test_rdoc_options
    data_methods = [:verbosity, :dry_run, :update_output_dir,
                    :force_output, :files]
    result = [0, false, true, false, [__FILE__]]

    options = @api.send(:rdoc_options, @path['rdoc_options'])
    assert_equal(result, data_methods.map {|m| options.send(m)})

    options = @api.send(:rdoc_options, @path['rdoc_options'].join(' '))
    assert_equal(result, data_methods.map {|m| options.send(m)})
  end

  def test_rdoc_store
    options = @api.send(:rdoc_options, @path['rdoc_options'])
    store = @api.send(:rdoc_store, options, 'dir')

    data = [store.dry_run, store.main, store.title, store.path]
    result = [false, nil, 'Title', 'dir']

    assert_equal(result, data)
  end

=begin
  def create_nodes
    @path['version'] = 'atom'
    atom_node = @feed.create_nodes(@path.dup, @path_blocks)
    @path['version'] = 'rss'
    rss_node = @feed.create_nodes(@path.dup, @path_blocks)
    [atom_node, rss_node]
  end

  def test_create_node
    atom_node, rss_node = create_nodes

    refute_nil(atom_node)
    refute_nil(rss_node)
    refute_nil(atom_node.node_info[:blocks])
    assert_equal('atom', atom_node['version'])
    assert_equal('rss', rss_node['version'])

    assert_raises(Webgen::NodeCreationError) do
      path = Webgen::Path.new('/test_feed_2') { StringIO.new("---\nunknow: yes") }
      @feed.create_nodes(path, 'unused')
    end
  end

  def test_content
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Erb')
    @website.ext.content_processor.register('Blocks')

    atom_node, rss_node = create_nodes
    assert_equal("hallo\n", @feed.content(rss_node))
    assert(@feed.content(atom_node) =~ /Thomas Leitner/)
    assert(@feed.content(atom_node) =~ /RealContent/)
  end

  def test_feed_entries
    atom_node, rss_node = create_nodes
    assert_equal([@index_en, @file_en], atom_node.feed_entries)
    assert_equal([@index_en, @file_en], rss_node.feed_entries)
  end
=end

end
