# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/html_head'

class TestHtmlHead < Minitest::Test

  include Webgen::TestHelper

  def setup
    setup_website
    @obj = Webgen::ContentProcessor::HtmlHead
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    @node = Webgen::Node.new(@root, 'test', 'test.en', {'lang' => 'en'})
  end

  def test_call
    context = Webgen::Context.new(@website, :chain => [@node])
    context.content = "</head>"
    Webgen::Node.new(@root, 'test', 'test.de', {'lang' => 'de'})
    assert_equal("\n<link type=\"text/html\" rel=\"alternate\" hreflang=\"de\" href=\"test.de\" /></head>",
                 @obj.call(context).content)
  end

  def test_tags_from_context_data
    @node.meta_info['meta'] = {'other' => 'me'}
    context = Webgen::Context.new(@website, :chain => [@node])
    context.persistent[:cp_html_head] = {
      :js_file => ['hallo.js', 'hallo2.js', 'hallo.js'],
      :js_inline => ["somescript", "anotherscript"],
      :css_file => ['hallo.css', 'hallo2.css', 'hallo.css'],
      :css_inline => ["somestyle", "anotherstyle"],
      :meta => {:lucky => 'me<"'}
    }
    assert_equal("\n<script type=\"text/javascript\" src=\"hallo.js\"></script>" +
                 "\n<script type=\"text/javascript\" src=\"hallo2.js\"></script>" +
                 "\n<script type=\"text/javascript\">//<![CDATA[\nsomescript\n//]]></script>" +
                 "\n<script type=\"text/javascript\">//<![CDATA[\nanotherscript\n//]]></script>" +
                 "\n<link rel=\"stylesheet\" href=\"hallo.css\" type=\"text/css\"/>" +
                 "\n<link rel=\"stylesheet\" href=\"hallo2.css\" type=\"text/css\"/>" +
                 "\n<style type=\"text/css\">/*<![CDATA[/*/\nsomestyle\n/*]]>*/</style>" +
                 "\n<style type=\"text/css\">/*<![CDATA[/*/\nanotherstyle\n/*]]>*/</style>" +
                 "\n<meta name=\"lucky\" content=\"me&lt;&quot;\" />" +
                 "\n<meta name=\"other\" content=\"me\" />", @obj.tags_from_context_data(context))

    context.persistent[:cp_html_head] = nil
    assert_equal("\n<meta name=\"other\" content=\"me\" />", @obj.tags_from_context_data(context))

  end

  def test_links_to_translations
    context = Webgen::Context.new(@website, :chain => [@node])

    de_node = Webgen::Node.new(@root, 'test', 'test.de', {'lang' => 'de'})
    assert_equal("\n<link type=\"text/html\" rel=\"alternate\" hreflang=\"de\" href=\"test.de\" />",
                 @obj.links_to_translations(context))

    de_node.meta_info['title'] = 'Deutscher Titel'
    assert_equal("\n<link type=\"text/html\" rel=\"alternate\" hreflang=\"de\" href=\"test.de\" " +
                 "lang=\"de\" title=\"Deutscher Titel\" />", @obj.links_to_translations(context))
  end

  def test_links_from_link_meta_info
    context = Webgen::Context.new(@website, :chain => [@node])

    @node.meta_info['link'] = {'javascript' => 'http://example.org', 'css' => ['http://example.org', 'test', 'unknown']}
    assert_equal("\n<script type=\"text/javascript\" src=\"http://example.org\"></script>" +
                 "\n<link rel=\"stylesheet\" href=\"http://example.org\" type=\"text/css\" />" +
                 "\n<link rel=\"stylesheet\" href=\"test.en\" type=\"text/css\" />",
                 @obj.links_from_link_meta_info(context))

    @node.meta_info['link'] = {'next' => 'test', 'start' => {'type' => 'text/xhtml', 'href' => 'http://example.org'},
      'alternate' => ['test', {'type' => 'text/html', 'href' => 'test'}, {'href' => 'unknown'}, {'type' => 'text/html'}]
    }
    assert_equal("\n<link href=\"test.en\" rel=\"alternate\" />" +
                 "\n<link href=\"test.en\" rel=\"alternate\" type=\"text/html\" />" +
                 "\n<link href=\"test.en\" rel=\"next\" type=\"text/html\" />" +
                 "\n<link href=\"http://example.org\" rel=\"start\" type=\"text/xhtml\" />",
                 @obj.links_from_link_meta_info(context))
  end

end
