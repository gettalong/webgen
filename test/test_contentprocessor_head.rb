# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/page'
require 'webgen/contentprocessor'

class TestContentProcessorHead < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_call
    obj = Webgen::ContentProcessor::Head.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test', {'meta' => {'other' => 'me'}})

    context = Webgen::Context.new(:chain => [node])
    context.content = '</head>'
    obj.call(context)
    assert_equal("\n<meta name=\"other\" content=\"me\" /></head>", context.content)

    context.content = '</head>'
    context.clone.persistent[:cp_head] = {
      :js_file => ['hallo.js', 'hallo2.js', 'hallo.js'],
      :js_inline => ["somescript", "anotherscript"],
      :css_file => ['hallo.css', 'hallo2.css', 'hallo.css'],
      :css_inline => ["somestyle", "anotherstyle"],
      :meta => {:lucky => 'me<"'}
    }
    node['meta'].clear
    obj.call(context)
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

end
