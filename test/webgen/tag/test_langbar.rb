# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/website'
require 'webgen/content_processor'
require 'webgen/path_handler/page_utils'
require 'webgen/tag/langbar'

class TestTagLangbar < MiniTest::Unit::TestCase

  class TestNode < Webgen::Node

    include Webgen::PathHandler::PageUtils

    def blocks
      node_info[:blocks]
    end

    def render_block(name, context)
      super(self, name, context)
    end

  end

  def test_call
    @obj = Webgen::Tag::Langbar
    @website, context = Test.setup_tag_test
    @website.expect(:config, {'website.link_to_current_page' => false})
    @website.expect(:tree, Webgen::Tree.new(@website))
    @website.expect(:logger, Logger.new(StringIO.new))
    @website.ext.item_tracker = MiniTest::Mock.new
    def (@website.ext.item_tracker).add(*args); end
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Blocks')
    @website.ext.content_processor.register('Ruby')

    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'file.html', '/file.html', {'lang' => 'en'})
    de_node = Webgen::Node.new(root, 'file.html', '/file.de.html', {'lang' => 'de'})
    other = Webgen::Node.new(root, 'other.html', '/other.html', {'lang' => 'en'})

    template = TestNode.new(root, 'tag.template', '/tag.template')
    template_data = File.read(File.join(Webgen.data_dir, 'passive_sources', 'templates', 'tag.template'))
    page = Webgen::Page.from_data(template_data)
    template.node_info[:blocks] = page.blocks
    template.meta_info.update(page.meta_info)

    de_link = '<a href="file.de.html">de</a>'
    en_link = '<span class="webgen-langbar-current-lang">en</span>'
    check_results(node, "#{de_link} | #{en_link}", de_link, "#{de_link} | #{en_link}", de_link)
    check_results(other, en_link, '', '', '')
  end

  def check_results(node, both_true, both_false, first_false, second_false)
    context = Webgen::Context.new(@website, :chain => [node])
    context[:config] = {'tag.langbar.template' => '/tag.template'}
    context[:config].update('tag.langbar.show_single_lang' => true, 'tag.langbar.show_own_lang' => true)
    assert_equal(both_true, @obj.call('langbar', '', context))

    context[:config].update('tag.langbar.show_single_lang' => false, 'tag.langbar.show_own_lang' => false)
    assert_equal(both_false, @obj.call('langbar', '', context))

    context[:config].update('tag.langbar.show_single_lang' => false, 'tag.langbar.show_own_lang' => true)
    assert_equal(first_false, @obj.call('langbar', '', context))

    context[:config].update('tag.langbar.show_single_lang' => true, 'tag.langbar.show_own_lang' => false)
    assert_equal(second_false, @obj.call('langbar', '', context))
  end

end
