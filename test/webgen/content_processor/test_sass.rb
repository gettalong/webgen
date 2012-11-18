# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/sass'
require 'webgen/path'

class TestSass < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_static_call
    setup_context
    @website.ext.sass_load_paths = []
    @website.config['content_processor.sass.options'] = {}
    cp = Webgen::ContentProcessor::Sass

    @context.content = "#main\n  :background-color #000"
    result = "#main {\n  background-color: black; }\n"
    assert_equal(result, cp.call(@context).content)

    @context.content = "#cont\n = 5"
    assert_error_on_line(Webgen::RenderError, 2) { cp.call(@context) }

    # test @import-ing of sass files
    content = "#main\n  background-image: url(relocatable('../dir2/file.test') + \"#iefix\")"
    result = "#main {\n  background-image: url(\"../../dir2/file.test#iefix\"); }\n"
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    dir = Webgen::Node.new(root, 'dir/', '/dir/')
    partial = Webgen::Node.new(dir, '_partial.sass', '/dir/_partial.sass')
    partial.node_info[:path] = Webgen::Path.new('test') { StringIO.new(content) }
    dirdir = Webgen::Node.new(dir, 'dir/', '/dir/dir/')
    sass = Webgen::Node.new(dirdir, 'file.sass', '/dir/dir/file.sass')
    dir2 = Webgen::Node.new(root, 'dir2/', '/dir2/')
    file = Webgen::Node.new(dir2, 'file.test', '/dir2/file.test')

    @context[:chain] = [sass]
    @context.content = "@import 'unknown'"
    assert_error_on_line(Webgen::RenderError, 1) { cp.call(@context) }

    @context.content = "@import 'dir/partial' \n@import 'dir/_partial' \n@import 'dir/partial.sass'"
    assert_equal("#{result}\n#{result}\n#{result}", cp.call(@context).content)
  end

end
