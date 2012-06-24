# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/website'
require 'webgen/content_processor'
require 'webgen/path_handler/page_utils'
require 'webgen/tag/langbar'

class TestTagLangbar < MiniTest::Unit::TestCase

  def test_call
    @obj = Webgen::Tag::Langbar
    @website, context = Test.setup_tag_test
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

    template = Test.setup_tag_template(root)

    de_link = '<a href="file.de.html" hreflang="de">de</a>'
    en_link = '<a class="webgen-langbar-current-lang" href="file.html" hreflang="en">en</a>'
    check_results(node, "#{de_link} | #{en_link}", de_link, "#{de_link} | #{en_link}", de_link)

    en_link = '<a class="webgen-langbar-current-lang" href="other.html" hreflang="en">en</a>'
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
