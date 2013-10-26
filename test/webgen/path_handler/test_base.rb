# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/base'
require 'time'

class TestPathHandlerBase < Minitest::Test

  include Webgen::TestHelper

  class TestPathHandler
    include Webgen::PathHandler::Base

    public :parent_node
    public :dest_path
    public :node_exists?
    public :create_node
  end

  def setup
    setup_website
    @obj = TestPathHandler.new(@website)
  end

  def test_create_node
    count = 0
    assert_nil(@obj.create_node(Webgen::Path.new('/test.html', 'draft' => true)))

    path = Webgen::Path.new('/path.html', 'dest_path' => '<parent><basename>(.<lang>)<ext>',
                            'modified_at' => 'unknown', 'parent_alcn' => '')
    node = @obj.create_node(path) {|n| count += 1; assert_kind_of(Webgen::PathHandler::Base::Node, n)}
    assert_equal(path, node.node_info[:path])
    assert_kind_of(Time, node.meta_info['modified_at'])
    assert_equal(1, count)
    assert_nil(node.content)
    def (@obj).content(node); node; end
    assert_equal(node, node.content)

    second_node = @obj.create_node(path) {|n| count += 1}
    assert_equal(1, count)
    assert_equal(second_node, node)
  end

  def test_parent_node
    assert_equal(@website.tree.dummy_root, @obj.parent_node(Webgen::Path.new('/')))
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    dir = Webgen::Node.new(root, 'dir/', '/dir/')
    assert_equal(root, @obj.parent_node(Webgen::Path.new('/test/')))
    assert_raises(Webgen::NodeCreationError) { @obj.parent_node(Webgen::Path.new('/hallo/other.page')) }
    assert_equal(dir, @obj.parent_node(Webgen::Path.new('/dir/test/')))
    assert_equal(root, @obj.parent_node(Webgen::Path.new('/dir/test/', 'parent_alcn' => '/')))
  end

  def test_dest_path
    config = @website.config
    config['website.lang'] = 'en'
    node = Webgen::Node.new(@website.tree.dummy_root, '/', '/', {:test => :value})

    assert_raises(Webgen::NodeCreationError) { @obj.dest_path(node, Webgen::Path.new('/test')) }

    check_dest_path = lambda do |path, mi, expected, parent = node|
      assert_equal(expected, @obj.dest_path(parent, Webgen::Path.new(path, mi)))
    end

    mi = {'dest_path' => '<parent><basename>(-<version>)(.<lang>)<ext>'}

    config['path_handler.lang_code_in_dest_path'] = true
    check_dest_path.call('/path.html', mi, '/path.html')
    check_dest_path.call('/path.en.html', mi, '/path.en.html')
    check_dest_path.call('/path.eo.html', mi, '/path.eo.html')

    config['path_handler.lang_code_in_dest_path'] = false
    check_dest_path.call('/path.html', mi, '/path.html')
    check_dest_path.call('/path.en.html', mi, '/path.html')
    check_dest_path.call('/path.eo.html', mi, '/path.html')

    config['path_handler.lang_code_in_dest_path'] = 'except_default'
    check_dest_path.call('/path.html', mi, '/path.html')
    check_dest_path.call('/path.en.html', mi, '/path.html')
    check_dest_path.call('/path.eo.html', mi, '/path.eo.html')
    check_dest_path.call('/dir/', mi, '/dir/')

    config['path_handler.version_in_dest_path'] = true
    check_dest_path.call('/path.html', mi.merge('version' => 'default'), '/path-default.html')
    check_dest_path.call('/path.html', mi.merge('version' => 'other'), '/path-other.html')

    config['path_handler.version_in_dest_path'] = false
    check_dest_path.call('/path.html', mi.merge('version' => 'default'), '/path.html')
    check_dest_path.call('/path.html', mi.merge('version' => 'other'), '/path.html')

    config['path_handler.version_in_dest_path'] = 'except_default'
    check_dest_path.call('/path.html', mi.merge('version' => 'default'), '/path.html')
    check_dest_path.call('/path.html', mi.merge('version' => 'other'), '/path-other.html')

    other = Webgen::Node.new(node, 'other.page', '/path.html')
    check_dest_path.call('/path.html', mi, '/path.html')
    check_dest_path.call('/path.en.html', mi, '/path.en.html')

    check_dest_path.call('/path.html#frag', mi, '/path.html#frag', other)
    frag = Webgen::Node.new(other, '#frag', '/path.html#frag')
    check_dest_path.call('/path.html#frag1', mi, '/path.html#frag1', frag)

    check_dest_path.call('/', mi, '/', @website.tree.dummy_root)

    index_en = Webgen::Node.new(node, 'index.page', '/index.html', {'lang' => 'en'})
    check_dest_path.call('/index.en.html', mi, '/index.html')
    check_dest_path.call('/index.en.html', {'dest_path' => "<parent>hallo.html"}, '/hallo.html')
    check_dest_path.call('/other.de.html', {'dest_path' => "<parent>index(.<lang>)<ext>"}, '/index.de.html')

    assert_raises(Webgen::NodeCreationError) do
      check_dest_path.call('/path.html', {'dest_path' => "<parent><year>/<month>/<basename><ext>"}, 'unused')
    end
    time = Time.parse('2008-09-04 08:15')
    check_dest_path.call('/path.html',
                         {'dest_path' => "<parent><year>/<month>/<day>-<basename><ext>", 'created_at' => time},
                         '/2008/09/04-path.html')


    dir = Webgen::Node.new(node, 'nested.path', '/dir1/dir2/dir3/')
    check_dest_path.call('/path.html', {'dest_path' => "<parent1><parent2><parent3><parent4>"},
                         'dir1dir2dir3', dir)
    check_dest_path.call('/path.html', {'dest_path' => "<parent-4><parent-3><parent-2><parent-1>"},
                         'dir1dir2dir3', dir)
    check_dest_path.call('/path.html', {'dest_path' => "<parent2..-1>"},
                         'dir2/dir3', dir)
    assert_raises(Webgen::NodeCreationError) do
      check_dest_path.call('/path.html', {'dest_path' => "<parent0>"}, 'unused')
    end

    check_dest_path.call('/path.html', {'dest_path' => "webgen:this is not changed"},
                         'this is not changed')

    assert_raises(Webgen::NodeCreationError) do
      check_dest_path.call('/path.html', {'dest_path' => "<hallo>"}, 'unused')
    end

  end

  def test_node_exists
    node = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    child_de = Webgen::Node.new(node, 'somename.html', '/somename.html', {'lang' => 'de'})
    frag_de = Webgen::Node.new(child_de, '#othertest', '/somename.html#data1')

    assert_equal(child_de, @obj.node_exists?(Webgen::Path.new('/somename.de.html'), '/unknown.html'))
    assert_equal(child_de, @obj.node_exists?(Webgen::Path.new('/other.page'), '/somename.html'))
    assert_equal(false, @obj.node_exists?(Webgen::Path.new('/somename.en.html', {'no_output' => true}),
                                          '/somename.html'))
    assert_equal(frag_de, @obj.node_exists?(Webgen::Path.new('/somename.de.html#othertest'), '/somename.html#no'))
    assert_equal(nil, @obj.node_exists?(Webgen::Path.new('/unknown'), '/unknown'))
  end

  def test_base_node_methods
    node = Webgen::PathHandler::Base::Node.new(@website.tree.dummy_root, '/', '/')
    child_de = Webgen::PathHandler::Base::Node.new(node, 'somename.html', '/somename.html',
                                                   {'lang' => 'de', 'title' => 'Somename'})
    @website.config = {'website.base_url' => 'http://example.com/sub', 'website.link_to_current_page' => true}

    assert_equal('http://example.com/sub/somename.html', child_de.url)

    assert_equal('<a href="somename.html" hreflang="de">Somename</a>', node.link_to(child_de))
    @website.config['website.link_to_current_page'] = false
    assert_equal('<span>Somename</span>', node.link_to(child_de))
  end

end
