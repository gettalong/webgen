# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/blackboard'

class TestNode < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @tree = Webgen::Tree.new(@website)
  end

  def test_initialize
    check_proc = proc do |node, parent, dest_path, cn, lcn, alcn, lang, mi|
      assert_equal(parent, node.parent)
      assert_equal(dest_path, node.dest_path)
      assert_equal(cn, node.cn)
      assert_equal(lcn, node.lcn)
      assert_equal(alcn, node.alcn)
      assert_equal(lang, node.lang)
      assert_kind_of(Webgen::Language, node.lang) if node.lang
      assert_equal(mi, node.meta_info)
      assert_equal({}, node.node_info)
    end

    node = Webgen::Node.new(@tree.dummy_root, '/', '/', {'lang' => 'de', :test => :value})
    check_proc.call(node, @tree.dummy_root, '/', '/', '/', '/', nil, {:test => :value})

    child = Webgen::Node.new(node, 'somename.html', '/somename.html',  {'lang' => 'de'})
    check_proc.call(child, node, '/somename.html', 'somename.html', 'somename.de.html',
                    '/somename.de.html', 'de', {})

    ['http://webgen.rubyforge.org', 'c:\\test'].each_with_index do |abspath, index|
      cn = "test#{index}.html"
      c = Webgen::Node.new(node, cn, abspath)
      check_proc.call(c, node, abspath, cn, cn, '/' + cn, nil, {})
    end
  end

  def test_meta_info_accessor
    node = Webgen::Node.new(@tree.dummy_root, '/', '/', {:test => :value})
    count = 0
    blackboard = Webgen::Blackboard.new
    blackboard.add_listener(:node_meta_info_accessed) do |alcn, key|
      assert_equal('/', alcn)
      assert_equal(:test, key)
      count += 1
    end
    @website.expect(:blackboard, blackboard)
    node[:test]
    assert_equal(1, count)
  end

  def test_type_checkers
    nodes = Test.create_default_nodes(@tree)
    assert(nodes[:root].is_directory?)
    assert(nodes[:somename_en].is_file?)
    assert(nodes[:somename_en_frag].is_fragment?)
    assert(nodes[:root].is_root?)
    assert(!nodes[:somename_en].is_root?)
    assert(nodes[:somename_en_fragnest].is_fragment?)
    assert(!nodes[:somename_en_fragnest].is_directory?)
  end

  def test_to_s
    node = Webgen::Node.new(@tree.dummy_root, '/', '/', {'lang' => 'de', :test => :value})
    assert_equal(node.alcn, node.to_s)
  end

  def test_matching
    root = Webgen::Node.new(@tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'somefile.html', 'somefile.de.html', {'lang' => 'de'})
    assert(node =~ '**/*')
    assert(node =~ '**/somefile.de.HTML')
    assert(node =~ '/**/somefile.*.html')
    assert(node !~ '/somefile.html')
    assert(node !~ '**/*.test')
  end

  def test_method_missing
    node = Webgen::Node.new(@tree.dummy_root, '/', '/')
    assert_raises(NoMethodError) { node.unknown }

    path_handler = MiniTest::Mock.new
    path_handler.expect(:send, :value, [:unknown, node])
    node.node_info[:path_handler] = path_handler

    assert_equal(:value, node.unknown)
    [path_handler, @website].each {|o| o.verify}
  end

  def test_route_to
    nodes = Test.create_default_nodes(@tree)
    @website.expect(:blackboard, Webgen::Blackboard.new)

    #arg is Node
    assert_equal('somename.en.html', nodes[:somename_en].route_to(nodes[:somename_en]))
    assert_equal('somename.de.html', nodes[:somename_en_frag].route_to(nodes[:somename_de]))
    assert_equal('file.html#frag', nodes[:dir].route_to(nodes[:dir_file_frag]))
    assert_equal('#frag', nodes[:dir_file].route_to(nodes[:dir_file_frag]))
    assert_equal('../dir2/index.html', nodes[:dir_file_frag].route_to(nodes[:dir2_index_en]))
    assert_equal('../dir2/index.html', nodes[:dir_file].route_to(nodes[:dir2_index_en]))

    assert_equal('./', nodes[:somename_en].route_to(nodes[:root]))
    assert_equal('../', nodes[:dir].route_to(nodes[:root]))
    assert_equal('dir/', nodes[:somename_en].route_to(nodes[:dir]))

    #arg is String
    assert_equal('somename.en.html', nodes[:somename_en].route_to('somename.en.html'))
    assert_equal('../other.html', nodes[:dir_file].route_to('/other.html'))
    assert_equal('../other', nodes[:dir_file].route_to('../other'))
    assert_equal('document/file2', nodes[:dir_file_frag].route_to('document/file2'))
    assert_equal('ftp://test/', nodes[:dir].route_to('ftp://test/'))

    #test args with '..' and '.': either too many of them or absolute path given
    assert_equal('../dir2', nodes[:dir_file].route_to('../../.././dir2'))
    assert_equal('../file', nodes[:dir_file].route_to('/dir/../file'))
    assert_equal('file', nodes[:dir_file].route_to('dir/../file'))

    #arg is something else
    assert_raises(ArgumentError) { nodes[:root].route_to(5) }

    @website.verify
  end

  def test_proxy_node
    nodes = Test.create_default_nodes(@tree)
    @website.expect(:blackboard, Webgen::Blackboard.new)

    assert_equal(nodes[:somename_en], nodes[:somename_en].proxy_node('en'))
    assert_equal(nodes[:dir2_index_en], nodes[:dir2].proxy_node('en'))
    assert_equal(nodes[:dir2_index_en], nodes[:dir2].proxy_node('en'))

    @website.verify
  end

  def test_level
    nodes = Test.create_default_nodes(@tree)
    assert_equal(0, nodes[:root].level)
    assert_equal(1, nodes[:dir].level)
    assert_equal(2, nodes[:dir_file].level)
    assert_equal(3, nodes[:dir_file_frag].level)
  end

  def test_link_to
    nodes = Test.create_default_nodes(@tree)

    @website.expect(:blackboard, Webgen::Blackboard.new)

    # general tests
    assert_equal('<a href="#frag">frag</a>',
                 nodes[:somename_en].link_to(nodes[:somename_en_frag]))
    assert_equal('<a href="#frag">link_text</a>',
                 nodes[:somename_en].link_to(nodes[:somename_en_frag], :link_text => 'link_text'))
    assert_equal('<a attr1="val1" href="#frag">frag</a>',
                 nodes[:somename_en].link_to(nodes[:somename_en_frag], 'attr1' => 'val1'))
    assert_equal('<a href="#frag">frag</a>',
                 nodes[:somename_en].link_to(nodes[:somename_en_frag], :attr1 => 'val1'))
    assert_equal('<a class="help" href="dir2/index.html">index en</a>',
                 nodes[:somename_en].link_to(nodes[:dir2_index_en]))

    # links to directories
    assert_equal('<a href="dir2/index.de.html">routed_de</a>',
                 nodes[:somename_de].link_to(nodes[:dir2]))
    assert_equal('<a href="dir2/index.html">routed</a>',
                 nodes[:somename_en].link_to(nodes[:dir2]))
    assert_equal('<a href="dir2/index.de.html">routed_de</a>',
                 nodes[:somename_en].link_to(nodes[:dir2], :lang => 'de'))

    # varying the website.link_to_current_page option
    config = MiniTest::Mock.new
    config.expect(:[], false, ['website.link_to_current_page'])
    @website.expect(:config, config)

    assert_equal('<span>routed</span>',
                 nodes[:dir2_index_en].link_to(nodes[:dir2]))
    assert_equal('<span>frag</span>',
                 nodes[:somename_en_frag].link_to(nodes[:somename_en_frag]))

    @website.verify
    config.verify

    config.expect(:[], true, ['website.link_to_current_page'])
    assert_equal('<a href="#frag">frag</a>',
                 nodes[:somename_en_frag].link_to(nodes[:somename_en_frag]))
    config.verify
  end

end
