# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tag'

class TestTagLangbar < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::Langbar.new
  end

  def create_default_nodes
    {
      :root => root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/', {'index_path' => 'index.html'}),
      :file_en => Webgen::Node.new(root, '/file1.html', 'file1.html', {'lang' => 'en', 'title' => 'File1'}),
      :index_en => Webgen::Node.new(root, '/index.html', 'index.html', {'lang' => 'en'}),
      :index_de => Webgen::Node.new(root, '/index.de.html', 'index.html', {'lang' => 'de'}),
    }
  end

  def test_call
    nodes = create_default_nodes

    de_link = '<a href="index.de.html">de</a>'
    en_link = '<span class="webgen-langbar-current-lang">en</span>'
    check_results(nodes[:index_en], "#{de_link} | #{en_link}", de_link, "#{de_link} | #{en_link}", de_link)

    check_results(nodes[:file_en], en_link, '', '', '')

    @obj.set_params('tag.langbar.show_single_lang' => true, 'tag.langbar.show_own_lang' => true, 'tag.langbar.separator' => ' --- ')
    assert_equal(["#{de_link} --- #{en_link}", false],
                 @obj.call('langbar', '', Webgen::Context.new(:chain => [nodes[:index_en]])))

    @obj.set_params('tag.langbar.show_single_lang' => true, 'tag.langbar.show_own_lang' => true,
                    'tag.langbar.lang_names' => {'de' => 'Deutsch'})
    assert_equal(["<a href=\"index.de.html\">Deutsch</a> | #{en_link}", false],
                 @obj.call('langbar', '', Webgen::Context.new(:chain => [nodes[:index_en]])))

    @obj.set_params('tag.langbar.show_single_lang' => true, 'tag.langbar.show_own_lang' => true,
                    'tag.langbar.process_output' => true)
    assert_equal(["#{de_link} | #{en_link}", true],
                 @obj.call('langbar', '', Webgen::Context.new(:chain => [nodes[:index_en]])))

    nodes[:index_en].unflag(:dirty)
    @website.blackboard.dispatch_msg(:node_changed?, nodes[:index_en])
    assert(!nodes[:index_en].flagged?(:dirty))
    nodes[:index_en].tree.delete_node(nodes[:index_de])
    @website.blackboard.dispatch_msg(:node_changed?, nodes[:index_en])
    assert(nodes[:index_en].flagged?(:dirty))
  end

  def check_results(node, both_true, both_false, first_false, second_false)
    context = Webgen::Context.new(:chain => [node])
    @obj.set_params('tag.langbar.show_single_lang'=>true, 'tag.langbar.show_own_lang'=>true)
    assert_equal(both_true, @obj.call('langbar', '', context).first)

    @obj.set_params('tag.langbar.show_single_lang'=>false, 'tag.langbar.show_own_lang'=>false)
    assert_equal(both_false, @obj.call('langbar', '', context).first)

    @obj.set_params('tag.langbar.show_single_lang'=>false, 'tag.langbar.show_own_lang'=>true)
    assert_equal(first_false, @obj.call('langbar', '', context).first)

    @obj.set_params('tag.langbar.show_single_lang'=>true, 'tag.langbar.show_own_lang'=>false)
    assert_equal(second_false, @obj.call('langbar', '', context).first)
  end

end
