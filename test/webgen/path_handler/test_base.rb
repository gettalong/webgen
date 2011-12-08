# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/path_handler/base'
require 'webgen/tree'
require 'time'
require 'logger'
require 'stringio'

class TestPathHandlerBase < MiniTest::Unit::TestCase

  class TestPathHandler
    include Webgen::PathHandler::Base

    public :parent_node
    public :dest_path
    public :node_exists?
    public :create_node
  end

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:tree, Webgen::Tree.new(@website))
    @obj = TestPathHandler.new(@website)
  end

  def test_content
    assert_nil(@obj.content(nil))
  end

  def test_create_node
    @website.expect(:logger, Logger.new(StringIO.new))

    assert_nil(@obj.create_node(Webgen::Path.new('/test.html', 'draft' => true)))

    path = Webgen::Path.new('/path.html', :src => '/path', 'dest_path' => ':parent:basename(.:lang):ext',
                            'modified_at' => 'unknown')
    node = @obj.create_node(path, @website.tree.dummy_root) {|n| assert_kind_of(Webgen::Node, n)}
    assert_equal('/path', node.node_info[:src])
    assert_kind_of(Time, node.meta_info['modified_at'])

    assert_raises(Webgen::NodeCreationError) { @obj.create_node(path, @website.tree.dummy_root) }
  end

  def test_parent_node
    assert_equal(@website.tree.dummy_root, @obj.parent_node(Webgen::Path.new('/')))
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    assert_equal(root, @obj.parent_node(Webgen::Path.new('/test/')))
    assert_raises(Webgen::NodeCreationError) { @obj.parent_node(Webgen::Path.new('/hallo/other.page')) }
  end

  def test_dest_path
    config = {'website.lang' => 'en'}
    @website.expect(:config, config)
    node = Webgen::Node.new(@website.tree.dummy_root, '/', '/', {:test => :value})

    assert_raises(Webgen::NodeCreationError) { @obj.dest_path(node, Webgen::Path.new('/test')) }

    check_dest_path = lambda do |path, mi, expected, parent = node|
      assert_equal(expected, @obj.dest_path(parent, Webgen::Path.new(path, mi)))
    end

    mi = {'dest_path' => ':parent:basename(.:lang):ext'}

    config['path_handler.lang_code_in_dest_path'] = true
    check_dest_path.call('/path.html', mi, '/path.html')
    check_dest_path.call('/path.en.html', mi, '/path.en.html')
    check_dest_path.call('/path.eo.html', mi, '/path.eo.html')

    config['path_handler.lang_code_in_dest_path'] = false
    check_dest_path.call('/path.html', mi, '/path.html')
    check_dest_path.call('/path.en.html', mi, '/path.html')
    check_dest_path.call('/path.eo.html', mi, '/path.html')

    config['path_handler.lang_code_in_dest_path'] = 'except_default_lang'

    check_dest_path.call('/path.html', mi, '/path.html')
    check_dest_path.call('/path.en.html', mi, '/path.html')
    check_dest_path.call('/path.eo.html', mi, '/path.eo.html')
    check_dest_path.call('/dir/', mi, '/dir/')

    other = Webgen::Node.new(node, 'other.page', '/path.html')
    check_dest_path.call('/path.html', mi, '/path.html')
    check_dest_path.call('/path.en.html', mi, '/path.en.html')

    check_dest_path.call('/path.html#frag', mi, '/path.html#frag', other)
    frag = Webgen::Node.new(other, '#frag', '/path.html#frag')
    check_dest_path.call('/path.html#frag1', mi, '/path.html#frag1', frag)

    check_dest_path.call('/', mi, '/', @website.tree.dummy_root)
    check_dest_path.call('/test/', {'dest_path' => "/:parent@hallo:hallo"}, '/hallo:hallo/')

    index_en = Webgen::Node.new(node, 'index.page', '/index.html', {'lang' => 'en'})
    check_dest_path.call('/index.en.html', mi, '/index.html')
    check_dest_path.call('/index.en.html', {'dest_path' => ":parent@hallo.html"}, '/hallo.html')
    check_dest_path.call('/other.de.html', {'dest_path' => ":parent@index(.:lang):ext"}, '/index.de.html')

    assert_raises(Webgen::NodeCreationError) do
      check_dest_path.call('/path.html', {'dest_path' => ":parent@:year/:month/:basename:ext"}, 'unused')
    end
    time = Time.parse('2008-09-04 08:15')
    check_dest_path.call('/path.html',
                         {'dest_path' => ":parent@:year/:month/:day-:basename:ext", 'created_at' => time},
                         '/2008/09/04-path.html')


    dir = Webgen::Node.new(node, 'nested.path', '/dir1/dir2/dir3/')
    check_dest_path.call('/path.html', {'dest_path' => ":parent[1]:parent[2]:parent[3]:parent[4]"},
                         'dir1dir2dir3', dir)
    check_dest_path.call('/path.html', {'dest_path' => ":parent[-4]:parent[-3]:parent[-2]:parent[-1]"},
                         'dir1dir2dir3', dir)
    check_dest_path.call('/path.html', {'dest_path' => ":parent[2..-1]"},
                         'dir2/dir3', dir)
    assert_raises(Webgen::NodeCreationError) do
      check_dest_path.call('/path.html', {'dest_path' => ":parent[0]"}, 'unused')
    end

    check_dest_path.call('/path.html', {'dest_path' => "webgen:this is not changed"},
                         'this is not changed')
  end

  def test_node_exists
    node = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    child_de = Webgen::Node.new(node, 'somename.html', '/somename.html', {'lang' => 'de'})
    frag_de = Webgen::Node.new(child_de, '#othertest', '/somename.html#data1')

    assert_equal(child_de, @obj.node_exists?(node, Webgen::Path.new('/somename.de.html'), '/unknown.html'))
    assert_equal(child_de, @obj.node_exists?(node, Webgen::Path.new('/other.page'), '/somename.html'))
    assert_equal(false, @obj.node_exists?(node, Webgen::Path.new('/somename.en.html', {'no_output' => true}),
                                          '/somename.html'))
    assert_equal(frag_de, @obj.node_exists?(child_de, Webgen::Path.new('/somename.de.html#othertest'), '/somename.html#no'))
    assert_equal(nil, @obj.node_exists?(node, Webgen::Path.new('/unknown'), '/unknown'))
  end

end
