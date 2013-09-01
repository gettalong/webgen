# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor'
require 'webgen/tag/menu'
require 'webgen/node_finder'

class TestTagMenu < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    setup_website
    setup_default_nodes(@website.tree)
    setup_tag_template(@website.tree['/'])
    @website.ext.node_finder = Webgen::NodeFinder.new(@website)

    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Blocks')
    @website.ext.content_processor.register('Ruby')

    context = Webgen::Context.new(@website, :chain => [@website.tree['/dir/subfile.html']])

    assert_tag_result("<ul class=\"other\"><li class=\"webgen-menu-level1 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"../\"></a><ul><li class=\"webgen-menu-level2 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"./\">dir</a><ul><li class=\"webgen-menu-level3 webgen-menu-item-selected\"><a href=\"subfile.html\">subfile</a></li></ul></li></ul></li></ul>",
                      context, {:ancestors => true}, 'nested', 'other', 'webgen-menu-level', 'webgen-menu-submenu', 'webgen-menu-submenu-inhierarchy', 'webgen-menu-item-selected')

    assert_tag_result("<ul class=\"menu\"><li class=\"level1 sub sub-hier\"><a href=\"../\"></a></li></ul><ul><li class=\"level2 sub sub-hier\"><a href=\"./\">dir</a></li></ul><ul><li class=\"level3 active\"><a href=\"subfile.html\">subfile</a></li></ul>",
                      context, {:ancestors => true}, 'flat', 'menu', 'level', 'sub', 'sub-hier', 'active')
  end

  def assert_tag_result(result, context, options, style, css_class, level, smenu, smenuh, selected)
    context[:config] = {'tag.menu.style' => style,
      'tag.menu.options' => options,
      'tag.menu.template' => '/tag.template',
      'tag.menu.css_class' => css_class,
      'tag.menu.item_level_class' => level,
      'tag.menu.item_submenu_class' => smenu,
      'tag.menu.item_submenu_inhierarchy_class' => smenuh,
      'tag.menu.item_selected_class' => selected}
    assert_equal(result, Webgen::Tag::Menu.call('menu', '', context))
  end

end
