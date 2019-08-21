# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/api'

class TestPathHandlerApi < Minitest::Test

  attr_reader :test_attr

  class SampleTestSubclass
  end

  include Webgen::TestHelper

  def setup
    setup_website('website.lang' => 'en')

    @api = Webgen::PathHandler::Api.new(@website)

    Webgen::Node.new(@website.tree.dummy_root, '/', '/')

    @page_file = File.dirname(__FILE__) + "/../../../API.rdoc"
    @path = Webgen::Path.new('/test.api', 'dest_path' => '<parent><basename><ext>',
                             'api_name' => 'my_api',
                             'dir_name' => 'my_dir',
                             'prefix_link_defs' => true,
                             'rdoc_options' => ['-t', 'Title', __FILE__, @page_file])
  end

  def teardown
    FileUtils.rm_rf(@website.directory)
  end

  def setup_for_create_nodes
    @website.ext.path_handler = Webgen::PathHandler.new(@website)
    @website.ext.path_handler.register('Directory')
    @website.ext.path_handler.register('Page')
    @website.ext.path_handler.register('Copy')
    @website.ext.link_definitions = {}
  end

  def assert_common_tests_for_create_nodes(test_alcn)
    assert(@website.tree[test_alcn])
    assert_equal([test_alcn, 'TestPathHandlerApi'],
                 @website.ext.link_definitions['my_api:TestPathHandlerApi'])
    assert(@website.tree["#{test_alcn}#method-i-setup"])
    assert_equal(["#{test_alcn}#method-i-setup", 'TestPathHandlerApi#setup'],
                 @website.ext.link_definitions['my_api:TestPathHandlerApi#setup'])
    assert(@website.tree["#{test_alcn}#attribute-i-test_attr"])
    assert_equal(["#{test_alcn}#attribute-i-test_attr", 'TestPathHandlerApi#test_attr'],
                 @website.ext.link_definitions['my_api:TestPathHandlerApi#test_attr'])
    assert(@website.tree['/my_dir/API_rdoc.en.html'])
    assert(@website.tree['/my_dir/TestPathHandlerApi/SampleTestSubclass.en.html'])

    cache_dir = @website.tmpdir(File.join('path_handler.api', 'my_api'))
    assert(File.directory?(cache_dir))
  end

  def test_create_nodes
    setup_for_create_nodes
    @api.create_nodes(@path, nil)
    assert_common_tests_for_create_nodes('/my_dir/TestPathHandlerApi.en.html')
  end

  def test_create_nodes_hierarchical
    setup_for_create_nodes
    @path['output_structure'] = 'hierarchical'
    @api.create_nodes(@path, nil)
    assert_common_tests_for_create_nodes('/my_dir/TestPathHandlerApi/index.en.html')
  end

  def test_rdoc_options
    data_methods = [:verbosity, :dry_run, :update_output_dir,
                    :force_output, :files]
    result = [0, false, true, false, [__FILE__, @page_file]]

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

end
