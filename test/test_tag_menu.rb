require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'
require 'webgen/tag/menu'

class TestTagMenu < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::Menu.new
  end

  def create_default_nodes
    {
      :root => root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/', {'index_path' => 'index.html'}),
      :dir1 => dir1 = Webgen::Node.new(root, '/dir1/', 'dir1/'),
      :dir11 => dir11 = Webgen::Node.new(dir1, '/dir1/dir11/', 'dir11/', {'index_path' => 'index.html'}),
      :file111_en => Webgen::Node.new(dir11, '/dir1/dir11/file111.en.html', 'file111.html', {'lang' => 'en', 'in_menu' => true}),
      :file111_de => Webgen::Node.new(dir11, '/dir1/dir11/file111.de.html', 'file111.html', {'lang' => 'de', 'in_menu' => true}),
      :index11_en => Webgen::Node.new(dir11, '/dir1/dir11/index.en.html', 'index.html', {'lang' => 'en', 'in_menu' => true}),
      :file11_en => file11 = Webgen::Node.new(dir1, '/dir1/file11.en.html', 'file11.html', {'lang' => 'en', 'in_menu' => true}),
      :file11_en_f1 => file11_f1 = Webgen::Node.new(file11, '/dir1/file11.en.html#f1', '#f1', {'in_menu' => true}),
      :file11_en_f11 => Webgen::Node.new(file11_f1, '/dir1/file11.en.html#f11', '#f11', {'in_menu' => true}),
      :file11_en_f2 => Webgen::Node.new(file11, '/dir1/file11.en.html#f2', '#f2', {'in_menu' => true}),
      :dir2 => dir2 = Webgen::Node.new(root, '/dir2/', 'dir2/'),
      :file21_en => Webgen::Node.new(dir2, '/dir2/file21.en.html', 'file21.html', {'lang' => 'en', 'in_menu' => true}),
      :dir3 => dir3 = Webgen::Node.new(root, '/dir3/', 'dir3/'),
      :file31_en => file31 = Webgen::Node.new(dir3, '/dir3/file31.en.html', 'file31.html', {'lang' => 'en', 'in_menu' => false}),
      :file31_en_f1 => Webgen::Node.new(file31, '/dir3/file31.en.html#f1', '#f1', {'in_menu' => true}),
      :file1_de => Webgen::Node.new(root, '/file1.de.html', 'file1.html', {'lang' => 'de', 'in_menu' => true}),
      :index_en => Webgen::Node.new(root, '/index.en.html', 'index.html', {'lang' => 'en'}),
    }
  end

  def build_menu(node, options)
    @obj.set_params(options_hash(*options))
    output = @obj.send(:specific_menu_tree_for, node)
    @obj.set_params({})
    output
  end

  def options_hash(start_level, min_levels, max_levels, subtree, used_nodes = 'all')
    {'tag.menu.start_level' => start_level, 'tag.menu.min_levels' => min_levels, 'tag.menu.max_levels' => max_levels,
      'tag.menu.show_current_subtree_only' => subtree, 'tag.menu.used_nodes' => used_nodes }
  end

  def test_call
    nodes = create_default_nodes

    output = @obj.call('menu', '', Webgen::ContentProcessor::Context.new(:chain => [nodes[:file11_en]]))
    assert_equal("<ul><li class=\"webgen-menu-level1 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"./\"></a>" +
                 "<ul><li class=\"webgen-menu-level2 webgen-menu-submenu\"><a href=\"dir11/index.en.html\"></a></li>" +
                 "<li class=\"webgen-menu-level2 webgen-menu-item-selected\"><span></span></li></ul></li>" +
                 "<li class=\"webgen-menu-level1 webgen-menu-submenu\"><a href=\"../dir2/\"></a></li>" +
                 "<li class=\"webgen-menu-level1 webgen-menu-submenu\"><a href=\"../dir3/\"></a></li></ul>", output)

    output = @obj.call('menu', '', Webgen::ContentProcessor::Context.new(:chain => [nodes[:index11_en]]))
    assert_equal("<ul><li class=\"webgen-menu-level1 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"../\"></a>" +
                 "<ul><li class=\"webgen-menu-level2 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><span></span>" +
                 "<ul><li class=\"webgen-menu-level3\"><a href=\"file111.en.html\"></a></li>" +
                 "<li class=\"webgen-menu-level3 webgen-menu-item-selected\"><span></span></li></ul></li>" +
                 "<li class=\"webgen-menu-level2\"><a href=\"../file11.en.html\"></a></li></ul></li>" +
                 "<li class=\"webgen-menu-level1 webgen-menu-submenu\"><a href=\"../../dir2/\"></a></li>" +
                 "<li class=\"webgen-menu-level1 webgen-menu-submenu\"><a href=\"../../dir3/\"></a></li></ul>", output)


    @obj.set_params('tag.menu.used_nodes' => 'fragments')
    output = @obj.call('menu', '', Webgen::ContentProcessor::Context.new(:chain => [nodes[:file11_en]]))
    @obj.set_params({})
    assert_equal("<ul><li class=\"webgen-menu-level1 webgen-menu-submenu\"><a href=\"#f1\"></a></li>" +
                 "<li class=\"webgen-menu-level1\"><a href=\"#f2\"></a></li></ul>", output)

    @obj.set_params('tag.menu.start_level' => 5)
    output = @obj.call('menu', '', Webgen::ContentProcessor::Context.new(:chain => [nodes[:file11_en]]))
    @obj.set_params({})
    assert_equal("", output)

    nodes.each {|k,v| v.dirty = false}
    @website.blackboard.dispatch_msg(:node_changed?, nodes[:file11_en])
    assert(!nodes[:file11_en].dirty)

    nodes[:index11_en].dirty_meta_info = true
    @website.blackboard.dispatch_msg(:node_changed?, nodes[:file11_en])
    assert(nodes[:file11_en].dirty)

    nodes.each {|k,v| v.dirty = false}
    nodes[:file11_en_f2]['in_menu'] = false
    @website.blackboard.dispatch_msg(:node_changed?, nodes[:file11_en])
    assert(nodes[:file11_en].dirty)
  end

  def test_menu_tree_for_lang_and_create_menu_tree
    nodes = create_default_nodes

    tree_en = @obj.send(:menu_tree_for_lang, 'en', nodes[:root])
    expected = [nodes[:dir1], nodes[:dir11], nodes[:file111_en], nodes[:index11_en],
                nodes[:file11_en], nodes[:file11_en_f1], nodes[:file11_en_f11], nodes[:file11_en_f2],
                nodes[:dir2], nodes[:file21_en],
                nodes[:dir3], nodes[:file31_en], nodes[:file31_en_f1]].collect {|n| n.absolute_lcn}

    assert_equal(expected, tree_en.to_lcn_list.flatten)

    tree_de = @obj.send(:menu_tree_for_lang, 'de', nodes[:root])
    expected = [nodes[:dir1], nodes[:dir11], nodes[:file111_de], nodes[:file1_de]].collect {|n| n.absolute_lcn}

    assert_equal(expected, tree_de.to_lcn_list.flatten)
  end

  def test_specific_menu_tree_for_and_build_specific_menu_tree
    nodes = create_default_nodes

    # testing min_levels and max_levels
    output = build_menu(nodes[:index_en], [1, 1, 1, true])
    expected = [nodes[:dir1], nodes[:dir2], nodes[:dir3]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    output = build_menu(nodes[:index_en], [1, 2, 1, true])
    expected = [nodes[:dir1], nodes[:dir2], nodes[:dir3]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    output = build_menu(nodes[:index_en], [1, 2, 2, true])
    expected = [nodes[:dir1], nodes[:dir11], nodes[:file11_en], nodes[:dir2], nodes[:file21_en],
                nodes[:dir3], nodes[:file31_en]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    # testing show_current_subtree_only
    output = build_menu(nodes[:file11_en], [1, 1, 2, true])
    expected = [nodes[:dir1], nodes[:dir11], nodes[:file11_en], nodes[:dir2], nodes[:dir3]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    output = build_menu(nodes[:file11_en], [1, 1, 2, false])
    expected = [nodes[:dir1], nodes[:dir11], nodes[:file11_en], nodes[:dir2], nodes[:file21_en],
                nodes[:dir3], nodes[:file31_en]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    # testing start_level
    output = build_menu(nodes[:index_en], [2, 1, 1, true])
    assert_equal([], output.to_lcn_list.flatten)

    output = build_menu(nodes[:file11_en], [2, 1, 2, true])
    expected = [nodes[:dir11], nodes[:file11_en]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    output = build_menu(nodes[:file11_en], [2, 1, 2, false])
    expected = [nodes[:dir11], nodes[:file11_en]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    output = build_menu(nodes[:file11_en], [2, 2, 2, false])
    expected = [nodes[:dir11], nodes[:file111_en], nodes[:index11_en],
                nodes[:file11_en], nodes[:file11_en_f1], nodes[:file11_en_f2]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    output = build_menu(nodes[:file111_en], [2, 1, 2, true])
    expected = [nodes[:dir11], nodes[:file111_en], nodes[:index11_en], nodes[:file11_en]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    # testing used_nodes=files setting
    output = build_menu(nodes[:file11_en], [2, 2, 2, false, 'files'])
    expected = [nodes[:dir11], nodes[:file111_en], nodes[:index11_en], nodes[:file11_en]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    output = build_menu(nodes[:file11_en], [1, 1, 1, true, 'files'])
    expected = [nodes[:dir1], nodes[:dir2]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    # testing used_nodes=fragments setting
    output = build_menu(nodes[:file11_en], [1, 1, 2, false, 'fragments'])
    expected = [nodes[:file11_en_f1], nodes[:file11_en_f2]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)

    output = build_menu(nodes[:file11_en], [1, 2, 2, false, 'fragments'])
    expected = [nodes[:file11_en_f1], nodes[:file11_en_f11], nodes[:file11_en_f2]].collect {|n| n.absolute_lcn}
    assert_equal(expected, output.to_lcn_list.flatten)
  end

  def test_create_output_and_menu_item_details
    nodes = create_default_nodes
    tree = build_menu(nodes[:file111_en], [1, 2, 3, true])
    context = Webgen::ContentProcessor::Context.new(:chain => [nodes[:file111_en]])
    assert_equal("<ul><li class=\"webgen-menu-level1 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"../\"></a>" +
                 "<ul><li class=\"webgen-menu-level2 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"index.en.html\"></a>" +
                 "<ul><li class=\"webgen-menu-level3 webgen-menu-item-selected\"><span></span></li>" +
                 "<li class=\"webgen-menu-level3\"><a href=\"index.en.html\"></a></li></ul></li>" +
                 "<li class=\"webgen-menu-level2\"><a href=\"../file11.en.html\"></a></li></ul></li>" +
                 "<li class=\"webgen-menu-level1 webgen-menu-submenu\"><a href=\"../../dir2/\"></a>" +
                 "<ul><li class=\"webgen-menu-level2\"><a href=\"../../dir2/file21.en.html\"></a></li></ul></li>" +
                 "<li class=\"webgen-menu-level1 webgen-menu-submenu\"><a href=\"../../dir3/\"></a>" +
                 "<ul><li class=\"webgen-menu-level2\"><a href=\"../../dir3/file31.en.html\"></a></li></ul></li></ul>",
                 @obj.send(:create_output, context, tree))
  end

end
