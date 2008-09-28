require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'
require 'webgen/common'

class TestCommonSitemap < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Common::Sitemap.new
    @nodes = create_sitemap_nodes
  end

  def do_assert(node, lang, honor_in_menu, any_lang, used_kinds, result)
    assert_equal(result.map {|name| @nodes[name].absolute_lcn },
                 @obj.create_sitemap(node, lang, {
                                       'common.sitemap.honor_in_menu' => honor_in_menu,
                                       'common.sitemap.any_lang' => any_lang,
                                       'common.sitemap.used_kinds' => used_kinds
                                     }).to_lcn_list.flatten)
  end

  def test_create_sitemap_and_node_chagned
    do_assert(@nodes[:file11_en], 'en', false, false, ['page'],
              [:dir1, :file11_en, :index_en])
    do_assert(@nodes[:file11_en], 'en', true, false, ['page'],
              [:dir1, :file11_en])
    do_assert(@nodes[:file11_en], 'en', false, false, ['page', 'other'],
              [:dir1, :file11_en, :dir2, :file21_en, :index_en])
    do_assert(@nodes[:file11_en], 'en', false, false, [],
              [:dir1, :file11_en, :file11_en_f1, :dir2, :file21_en, :index_en])
    do_assert(@nodes[:file11_en], 'en', false, false, ['noone'],
              [])
    do_assert(@nodes[:file11_en], 'en', false, false, ['page', 'directory'],
              [:dir1, :file11_en, :dir2, :index_en])
    do_assert(@nodes[:file11_en], 'en', true, false, ['page', 'directory'],
              [:dir1, :file11_en])

    do_assert(@nodes[:file1_de], 'de', false, false, ['page'],
              [:file1_de])
    do_assert(@nodes[:file1_de], 'de', false, true, ['page'],
              [:dir1, :file11_en, :file1_de, :index_en])

    @nodes[:file11_en].unflag(:dirty)
    @website.blackboard.dispatch_msg(:node_changed?, @nodes[:file11_en])
    assert(!@nodes[:file11_en].flagged(:dirty))

    @nodes[:file11_en].flag(:dirty_meta_info)
    @website.blackboard.dispatch_msg(:node_changed?, @nodes[:file11_en])
    assert(@nodes[:file11_en].flagged(:dirty))
  end

end
