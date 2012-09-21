# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor'
require 'webgen/tag/menu'
require 'webgen/node_finder'

class TestTagMenu < MiniTest::Unit::TestCase

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

    assert_tag_result("<ul><li class=\"webgen-menu-level1 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"../\"></a><ul><li class=\"webgen-menu-level2 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"./\">dir</a><ul><li class=\"webgen-menu-level3 webgen-menu-item-selected\"><a href=\"subfile.html\">subfile</a></li></ul></li></ul></li></ul>",
                      context, {:ancestors => true}, 'nested')

    assert_tag_result("<ul><li class=\"webgen-menu-level1 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"../\"></a></li></ul><ul><li class=\"webgen-menu-level2 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"><a href=\"./\">dir</a></li></ul><ul><li class=\"webgen-menu-level3 webgen-menu-item-selected\"><a href=\"subfile.html\">subfile</a></li></ul>",
                      context, {:ancestors => true}, 'flat')
  end

  def assert_tag_result(result, context, options, style)
    context[:config] = {'tag.menu.style' => style,
      'tag.menu.options' => options,
      'tag.menu.template' => '/tag.template'}
    assert_equal(result, Webgen::Tag::Menu.call('menu', '', context))
  end

  def test_static_menu_item_details
    setup_website
    setup_default_nodes(@website.tree)
    obj = Webgen::Tag::Menu

    assert_equal(["class=\"webgen-menu-level1 webgen-menu-submenu\"",
                  "<a href=\"file.de.html\" hreflang=\"de\">file de</a>"],
                 obj.menu_item_details(@website.tree['/file.en.html'], @website.tree['/file.de.html'],
                                       'en', 1, true))
    assert_equal(["class=\"webgen-menu-level2 webgen-menu-submenu webgen-menu-submenu-inhierarchy\"",
                  "<a href=\"./\"></a>"],
                 obj.menu_item_details(@website.tree['/file.en.html'], @website.tree['/'],
                                       'en', 2, true))
    assert_equal(["class=\"webgen-menu-level2 webgen-menu-submenu webgen-menu-item-selected\"",
                  "<a href=\"file.en.html\" hreflang=\"en\">file en</a>"],
                 obj.menu_item_details(@website.tree['/file.en.html'], @website.tree['/file.en.html'],
                                       'en', 2, true))
    assert_equal(["class=\"webgen-menu-level3\"",
                  "<a href=\"file.de.html\" hreflang=\"de\">file de</a>"],
                 obj.menu_item_details(@website.tree['/file.en.html'], @website.tree['/file.de.html'],
                                       'de', 3, false))
  end

end
