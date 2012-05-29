# -*- encoding: utf-8 -*-

require 'helper'
require 'tmpdir'
require 'webgen/content_processor/sass'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/path'
require 'stringio'

class TestSass < MiniTest::Unit::TestCase

  include Test::WebgenAssertions

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    website.ext.sass_load_paths = []
    website.expect(:config, {'content_processor.sass.options' => {}})
    website.expect(:tmpdir, Dir.tmpdir, ['sass'])
    cp = Webgen::ContentProcessor::Sass

    context.content = "#main\n  :background-color #000"
    result = "#main {\n  background-color: black; }\n"
    assert_equal(result, cp.call(context).content)

    context.content = "#cont\n = 5"
    assert_error_on_line(Webgen::RenderError, 2) { cp.call(context) }

    # test @import-ing of sass files
    content = "#main\n  background-image: relocatable('/dir2/file.test')"
    result = "#main {\n  background-image: url(\"../dir2/file.test\"); }\n"
    website.ext.item_tracker = Object.new
    def (website.ext.item_tracker).add(*args); end
    website.expect(:tree, Webgen::Tree.new(website))
    root = Webgen::Node.new(website.tree.dummy_root, '/', '/')
    dir = Webgen::Node.new(root, 'dir/', '/dir/')
    partial = Webgen::Node.new(dir, '_partial.sass', '/dir/_partial.sass')
    partial.node_info[:path] = Webgen::Path.new('test') { StringIO.new(content) }
    sass = Webgen::Node.new(dir, 'file.sass', '/dir/file.sass')
    dir2 = Webgen::Node.new(root, 'dir2/', '/dir2/')
    file = Webgen::Node.new(dir2, 'file.test', '/dir2/file.test')

    context[:chain] = [sass]
    context.content = "@import 'unknown'"
    assert_error_on_line(Webgen::RenderError, 1) { cp.call(context) }

    context.content = "@import 'dir/partial' \n@import 'dir/_partial' \n@import 'dir/partial.sass'"
    assert_equal("#{result}\n#{result}\n#{result}", cp.call(context).content)
  end

end
