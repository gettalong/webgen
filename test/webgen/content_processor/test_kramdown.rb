# -*- encoding: utf-8 -*-

require 'webgen/test_helper'

class TestContentProcessorKramdown < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    require 'webgen/content_processor/kramdown' rescue skip('Library kramdown not installed')
    setup_context
    cp = Webgen::ContentProcessor::Kramdown
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    Webgen::Node.new(root, 'hello.html', '/hello.en.html')
    @website.config['content_processor.kramdown.options'] = {:auto_ids => true}
    @website.config['content_processor.kramdown.handle_links'] = true
    @website.config['content_processor.kramdown.ignore_unknown_fragments'] = false

    @website.ext.link_definitions = {'hallo' => ['/hello.html', 'Hello you']}
    @website.ext.tag = Object.new
    @website.ext.tag.define_singleton_method(:call) {|*args| 'hello.en.html'}

    # test normal invocation
    @context.content = '# header'
    assert_equal("<h1 id=\"header\">header</h1>\n", cp.call(@context).content)

    # test usage of link definitions
    @context.content = 'Link [hallo]'
    assert_equal("<p>Link <a href=\"hello.en.html\" title=\"Hello you\">hallo</a></p>\n", cp.call(@context).content)

    # test automatic handling of links
    @website.config['content_processor.kramdown.handle_links'] = true
    @context.content = 'Link [test](hello.html)'
    assert_equal("<p>Link <a href=\"hello.en.html\">test</a></p>\n", cp.call(@context).content)
    @context.content = 'Link ![test](hello.html)'
    assert_equal("<p>Link <img src=\"hello.en.html\" alt=\"test\" /></p>\n", cp.call(@context).content)

    @website.config['content_processor.kramdown.handle_links'] = false
    @context.content = 'Link [test](hello.html)'
    assert_equal("<p>Link <a href=\"hello.html\">test</a></p>\n", cp.call(@context).content)
    @context.content = 'Link ![test](hello.html)'
    assert_equal("<p>Link <img src=\"hello.html\" alt=\"test\" /></p>\n", cp.call(@context).content)

    # test warning messages
    @context.content = '{::comment}'
    cp.call(@context)
    assert_equal("<p>{::comment}</p>\n", @context.content)
    assert_log_match(/No stop tag for extension 'comment' found/)
  end

end
