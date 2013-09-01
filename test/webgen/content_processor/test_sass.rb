# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path'

class TestSass < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    require 'webgen/content_processor/sass' rescue skip('Library sass not installed')
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
    content = "@import 'dir/other'\n#main\n  background-image: url(relocatable('../dir2/file.test') + \"#iefix\")"
    result = "#id {\n  color: white; }\n\n#main {\n  background-image: url(\"../../dir2/file.test#iefix\"); }\n"
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    dir = Webgen::Node.new(root, 'dir/', '/dir/')
    partial = Webgen::Node.new(dir, '_partial.sass', '/dir/_partial.sass')
    partial.node_info[:path] = Webgen::Path.new('test') { StringIO.new(content) }
    dirdir = Webgen::Node.new(dir, 'dir/', '/dir/dir/')
    sass = Webgen::Node.new(dirdir, 'file.sass', '/dir/dir/file.sass')
    partial2 = Webgen::Node.new(dirdir, '_other.scss', '/dir/dir/_other.scss')
    partial2.node_info[:path] = Webgen::Path.new('test') { StringIO.new('#id { color:white; }') }
    dir2 = Webgen::Node.new(root, 'dir2/', '/dir2/')
    file = Webgen::Node.new(dir2, 'file.test', '/dir2/file.test')

    @context[:chain] = [sass]
    @context.content = "@import 'unknown'"
    assert_error_on_line(Webgen::RenderError, 1) { cp.call(@context) }

    @context.content = "@import '../partial' \n@import '../_partial' \n@import '../partial.sass'"
    assert_equal("#{result}\n#{result}\n#{result}", cp.call(@context).content)
  end

  def teardown
    FileUtils.rm_rf(@website.directory) if @website
  end

end
