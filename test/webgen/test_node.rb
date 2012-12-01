# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/node'

class TestNode < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def setup
    setup_website
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

    node = Webgen::Node.new(@website.tree.dummy_root, '/', '/', {'lang' => 'de', :test => :value})
    check_proc.call(node, @website.tree.dummy_root, '/', '/', '/', '/', nil, {:test => :value})

    child = Webgen::Node.new(node, 'somename.html', '/somename.html',  {'lang' => 'de'})
    check_proc.call(child, node, '/somename.html', 'somename.html', 'somename.de.html',
                    '/somename.de.html', 'de', {})

    ['http://webgen.rubyforge.org', 'c:\\test'].each_with_index do |abspath, index|
      cn = "test#{index}.html"
      c = Webgen::Node.new(node, cn, abspath)
      check_proc.call(c, node, abspath, cn, cn, '/' + cn, nil, {})
    end
  end

  def test_type_checkers
    setup_default_nodes(@website.tree)
    assert(@website.tree['/'].is_directory?)
    assert(@website.tree['/file.en.html'].is_file?)
    assert(@website.tree['/file.en.html#frag'].is_fragment?)
    assert(@website.tree['/'].is_root?)
    assert(!@website.tree['/file.en.html'].is_root?)
    assert(@website.tree['/file.en.html#nested'].is_fragment?)
    assert(!@website.tree['/file.en.html#nested'].is_directory?)
  end

  def test_is_ancestor_of
    setup_default_nodes(@website.tree)

    assert(@website.tree['/'].is_ancestor_of?(@website.tree['/file.en.html']))
    assert(@website.tree['/'].is_ancestor_of?(@website.tree['/dir/']))

    assert(@website.tree['/dir/'].is_ancestor_of?(@website.tree['/dir/subfile.html']))

    assert(@website.tree['/'].is_ancestor_of?(@website.tree['/dir/subfile.html#frag']))
    assert(@website.tree['/dir/'].is_ancestor_of?(@website.tree['/dir/subfile.html#frag']))
    assert(@website.tree['/dir/subfile.html'].is_ancestor_of?(@website.tree['/dir/subfile.html#frag']))

    refute(@website.tree['/dir/'].is_ancestor_of?(@website.tree['/dir2/index.en.html']))
    refute(@website.tree['/dir/'].is_ancestor_of?(@website.tree['/file.en.html']))
    refute(@website.tree['/dir/subfile.html'].is_ancestor_of?(@website.tree['/file.en.html']))
    refute(@website.tree['/dir2/index.en.html'].is_ancestor_of?(@website.tree['/dir/subfile.html']))
  end

  def test_to_s
    node = Webgen::Node.new(@website.tree.dummy_root, '/', '/', {'lang' => 'de', :test => :value})
    assert_equal(node.alcn, node.to_s)
  end

  def test_matching
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'somefile.html', 'somefile.de.html', {'lang' => 'de'})
    assert(node =~ '**/*')
    assert(node =~ '**/somefile.de.HTML')
    assert(node =~ '/**/somefile.*.html')
    assert(node !~ '/somefile.html')
    assert(node !~ '**/*.test')
  end

  def test_method_missing
    node = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    assert_raises(NoMethodError) { node.unknown }
    refute(node.respond_to?(:unknown))

    path_handler = Object.new
    def path_handler.unknown(node); :value; end
    node.node_info[:path_handler] = path_handler

    assert(node.respond_to?(:unknown))
    assert_equal(:value, node.unknown)
  end

  def test_route_to
    tree = @website.tree
    setup_default_nodes(tree)

    assert_equal('file.en.html', tree['/file.en.html'].route_to(tree['/file.en.html']))
    assert_equal('file.de.html', tree['/file.en.html#frag'].route_to(tree['/file.de.html']))
    assert_equal('subfile.html#frag', tree['/dir/'].route_to(tree['/dir/subfile.html#frag']))
    assert_equal('#frag', tree['/dir/subfile.html'].route_to(tree['/dir/subfile.html#frag']))
    assert_equal('../dir2/index.en.html', tree['/dir/subfile.html#frag'].route_to(tree['/dir2/index.en.html']))
    assert_equal('../dir2/index.en.html', tree['/dir/subfile.html'].route_to(tree['/dir2/index.en.html']))

    assert_equal('./', tree['/file.en.html'].route_to(tree['/']))
    assert_equal('../', tree['/dir/'].route_to(tree['/']))
    assert_equal('dir/', tree['/file.en.html'].route_to(tree['/dir/']))

    n = Webgen::Node.new(tree['/'], 'testing', '../../.././dir2')
    assert_equal('../dir2', tree['/dir/subfile.html'].route_to(n))
  end

  def test_proxy_node
    tree = @website.tree
    setup_default_nodes(tree)

    assert_equal(tree['/file.en.html'], tree['/file.en.html'].proxy_node('en'))
    assert_equal(tree['/dir2/index.en.html'], tree['/dir2/'].proxy_node('en'))
    assert_equal(tree['/dir2/index.en.html'], tree['/dir2/'].proxy_node('en'))

    @website.ext.item_tracker = MiniTest::Mock.new
    @website.ext.item_tracker.expect(:add, nil, [:a, :b, :c, :d])
    tree['/dir/subfile.html'].meta_info['proxy_path'] = 'holla'
    assert_equal(tree['/dir/subfile.html'], tree['/dir/subfile.html'].proxy_node('pt'))
  end

  def test_level
    setup_default_nodes(@website.tree)
    assert_equal(0, @website.tree['/'].level)
    assert_equal(1, @website.tree['/dir/'].level)
    assert_equal(2, @website.tree['/dir/subfile.html'].level)
    assert_equal(3, @website.tree['/dir/dir/file.html'].level)
  end

  def test_link_to
    tree = @website.tree
    setup_default_nodes(tree)

    # general tests
    assert_equal('<a href="#frag">frag</a>',
                 tree['/file.en.html'].link_to(tree['/file.en.html#frag']))
    assert_equal('<a href="#frag">link_text</a>',
                 tree['/file.en.html'].link_to(tree['/file.en.html#frag'], 'en', 'link_text' => 'link_text'))
    assert_equal('<a attr1="val1" href="#frag">frag</a>',
                 tree['/file.en.html'].link_to(tree['/file.en.html#frag'], 'en', 'attr1' => 'val1'))
    assert_equal('<a attr1="val1" href="#frag">frag</a>',
                 tree['/file.en.html'].link_to(tree['/file.en.html#frag'], 'en', :attr1 => 'val1'))
    assert_equal('<a class="help" href="dir2/index.en.html" hreflang="en">index en</a>',
                 tree['/file.en.html'].link_to(tree['/dir2/index.en.html']))

    # links to directories
    assert_equal('<a href="dir2/index.de.html" hreflang="de">routed de</a>',
                 tree['/file.de.html'].link_to(tree['/dir2/']))
    assert_equal('<a class="help" href="dir2/index.en.html" hreflang="en">routed</a>',
                 tree['/file.en.html'].link_to(tree['/dir2/']))
    assert_equal('<a href="dir2/index.de.html" hreflang="de">routed de</a>',
                 tree['/file.en.html'].link_to(tree['/dir2/'], 'de'))
  end

  def test_versions
    root = Webgen::Node.new(Webgen::Tree.new('website').dummy_root, '/', '/')
    n1 = Webgen::Node.new(root, 'file.html', '/file.html', 'version' => 'html')
    n1.node_info[:path] = '/file.html'
    n2 = Webgen::Node.new(root, 'file.pdf', '/file.pdf', 'version' => 'pdf')
    n2.node_info[:path] = '/file.html'
    n3 = Webgen::Node.new(root, 'file.orig', '/file.orig', 'version' => 'html')
    n3.node_info[:path] = '/file.other'

    assert_equal({'html' => n1, 'pdf' => n2}, n1.versions)
    assert_equal({'html' => n1, 'pdf' => n2}, n2.versions)
    assert_equal({'html' => n3}, n3.versions)
  end

end
