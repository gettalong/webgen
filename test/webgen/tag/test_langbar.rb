# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor'
require 'webgen/tag/langbar'

class TestTagLangbar < Minitest::Test

  include Webgen::TestHelper

  def test_call
    setup_context
    @obj = Webgen::Tag::Langbar
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Blocks')
    @website.ext.content_processor.register('Ruby')

    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'file.html', '/file.html', {'lang' => 'en'})
    de_node = Webgen::Node.new(root, 'file.html', '/file.de.html', {'lang' => 'de'})
    other = Webgen::Node.new(root, 'other.html', '/other.html', {'lang' => 'en'})
    setup_tag_template(root)

    de_link = '<a href="file.de.html" hreflang="de">de</a>'
    en_link = '<a class="webgen-langbar-current-lang" href="file.html" hreflang="en">en</a>'
    check_results(node, "#{de_link} | #{en_link}", de_link, "#{de_link} | #{en_link}", de_link, ' | ')
    check_results(node, "#{de_link} --- #{en_link}", de_link, "#{de_link} --- #{en_link}", de_link, ' --- ')

    en_link = '<a class="webgen-langbar-current-lang" href="other.html" hreflang="en">en</a>'
    check_results(other, en_link, '', '', '', ' | ')

    @context[:chain] = [node]
    @context[:config] = {'tag.langbar.template' => '/tag.template', 'tag.langbar.mapping' => {'de' => 'Deutsch'}}
    assert_equal('<a href="file.de.html" hreflang="de">Deutsch</a>', @obj.call('langbar', '', @context))
  end

  def check_results(node, both_true, both_false, first_false, second_false, separator)
    @context[:chain] = [node]
    @context[:config] = {'tag.langbar.template' => '/tag.template',
      'tag.langbar.separator' => separator,
      'tag.langbar.mapping' => {}
    }

    @context[:config].update('tag.langbar.show_single_lang' => true, 'tag.langbar.show_own_lang' => true)
    assert_equal(both_true, @obj.call('langbar', '', @context))

    @context[:config].update('tag.langbar.show_single_lang' => false, 'tag.langbar.show_own_lang' => false)
    assert_equal(both_false, @obj.call('langbar', '', @context))

    @context[:config].update('tag.langbar.show_single_lang' => false, 'tag.langbar.show_own_lang' => true)
    assert_equal(first_false, @obj.call('langbar', '', @context))

    @context[:config].update('tag.langbar.show_single_lang' => true, 'tag.langbar.show_own_lang' => false)
    assert_equal(second_false, @obj.call('langbar', '', @context))
  end

end
