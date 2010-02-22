# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/page'
require 'webgen/contentprocessor'

class TestContentProcessorHead < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::ContentProcessor::Head.new
    @root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    @node = Webgen::Node.new(@root, 'test.en', 'test', {'lang' => 'en'})
  end

  def test_meta_information
    context = Webgen::Context.new(:chain => [@node])
    context.content = '</head>'
    @node['meta'] = {'other' => 'me'}
    @obj.call(context)
    assert_equal("\n<meta name=\"other\" content=\"me\" /></head>", context.content)
  end

  def test_persistent_information
    context = Webgen::Context.new(:chain => [@node])
    context.content = '</head>'
    context.clone.persistent[:cp_head] = {
      :js_file => ['hallo.js', 'hallo2.js', 'hallo.js'],
      :js_inline => ["somescript", "anotherscript"],
      :css_file => ['hallo.css', 'hallo2.css', 'hallo.css'],
      :css_inline => ["somestyle", "anotherstyle"],
      :meta => {:lucky => 'me<"'}
    }
    @obj.call(context)
    assert_equal("\n<script type=\"text/javascript\" src=\"hallo.js\"></script>" +
                 "\n<script type=\"text/javascript\" src=\"hallo2.js\"></script>" +
                 "\n<script type=\"text/javascript\">\nsomescript\n</script>" +
                 "\n<script type=\"text/javascript\">\nanotherscript\n</script>" +
                 "\n<link rel=\"stylesheet\" href=\"hallo.css\" type=\"text/css\"/>" +
                 "\n<link rel=\"stylesheet\" href=\"hallo2.css\" type=\"text/css\"/>" +
                 "\n<style type=\"text/css\"><![CDATA[/\nsomestyle\n]]></style>" +
                 "\n<style type=\"text/css\"><![CDATA[/\nanotherstyle\n]]></style>" +
                 "\n<meta name=\"lucky\" content=\"me&lt;&quot;\" /></head>", context.content)
  end

  def test_links_to_other_lang_nodes
    context = Webgen::Context.new(:chain => [@node])
    context.content = '</head>'
    @obj.call(context)
    assert_equal("</head>", context.content)

    de_node = Webgen::Node.new(@root, 'test.de', 'test', {'lang' => 'de'})
    @obj.call(context)
    assert_equal("\n<link type=\"text/html\" rel=\"alternate\" hreflang=\"de\" href=\"test.de\" /></head>", context.content)

    context.content = '</head>'
    de_node['title'] = 'Deutscher Titel'
    @obj.call(context)
    assert_equal("\n<link type=\"text/html\" rel=\"alternate\" hreflang=\"de\" href=\"test.de\" " +
                 "lang=\"de\" title=\"Deutscher Titel\" /></head>", context.content)
  end

  def test_javascript_and_css_links
    context = Webgen::Context.new(:chain => [@node])
    context.content = '</head>'
    @node['link'] = {'javascript' => 'http://example.org', 'css' => ['http://example.org', 'test', 'unknown']}
    @obj.call(context)
    assert_equal("\n<script type=\"text/javascript\" src=\"http://example.org\"></script>" +
                 "\n<link rel=\"stylesheet\" href=\"http://example.org\" type=\"text/css\" />" +
                 "\n<link rel=\"stylesheet\" href=\"test.en\" type=\"text/css\" /></head>", context.content)
  end

  def test_generic_links
    context = Webgen::Context.new(:chain => [@node])
    context.content = '</head>'
    @node['link'] = {'next' => 'test', 'start' => {'type' => 'text/xhtml', 'href' => 'http://example.org'},
      'alternate' => ['test', {'type' => 'text/html', 'href' => 'test'}, {'href' => 'unknown'}, {'type' => 'text/html'}]
    }
    @obj.call(context)
    assert_equal("\n<link href=\"test.en\" rel=\"alternate\" />" +
                 "\n<link href=\"test.en\" rel=\"alternate\" type=\"text/html\" />" +
                 "\n<link href=\"test.en\" rel=\"next\" type=\"text/html\" />" +
                 "\n<link href=\"http://example.org\" rel=\"start\" type=\"text/xhtml\" /></head>", context.content)
    context.content = '</head>'
    @obj.call(context)
    assert_equal("\n<link href=\"test.en\" rel=\"alternate\" />" +
                 "\n<link href=\"test.en\" rel=\"alternate\" type=\"text/html\" />" +
                 "\n<link href=\"test.en\" rel=\"next\" type=\"text/html\" />" +
                 "\n<link href=\"http://example.org\" rel=\"start\" type=\"text/xhtml\" /></head>", context.content)
  end

end
