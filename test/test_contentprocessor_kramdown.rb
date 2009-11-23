# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorKramdown < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_call
    obj = Webgen::ContentProcessor::Kramdown.new
    node = Webgen::Node.new(Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/'), 'test', 'test')
    hello = Webgen::Node.new(node.tree.root, 'hello.en.html', 'hello.html')

    # test normal invocation
    context = Webgen::Context.new(:content => '# header', :chain => [node])
    assert_equal("<h1 id=\"header\">header</h1>\n", obj.call(context).content)

    # test automatic handling of links
    @website.config['contentprocessor.kramdown.handle_links'] = true
    context.content = 'Link [test](hello.html)'
    assert_equal("<p>Link <a href=\"hello.en.html\">test</a></p>\n", obj.call(context).content)
    context.content = 'Link ![test](hello.html)'
    assert_equal("<p>Link <img alt=\"test\" src=\"hello.en.html\" /></p>\n", obj.call(context).content)

    @website.config['contentprocessor.kramdown.handle_links'] = false
    context.content = 'Link [test](hello.html)'
    assert_equal("<p>Link <a href=\"hello.html\">test</a></p>\n", obj.call(context).content)
    context.content = 'Link ![test](hello.html)'
    assert_equal("<p>Link <img alt=\"test\" src=\"hello.html\" /></p>\n", obj.call(context).content)

    # test warning messages
    output = StringIO.new('')
    @website.logger = ::Logger.new(output)
    @website.logger.level = Logger::WARN

    context.content = '{::unknownextension::}'
    obj.call(context)
    assert_equal("", context.content)
    output.rewind; assert_match(/No extension named 'unknownextension' found/, output.read)

    # test raised error when library not found
    def obj.require(lib); raise LoadError; end
    assert_raise(Webgen::LoadError) { obj.call(context) }
  end

end
