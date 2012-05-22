# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/tag/tikz'
require 'webgen/context'
require 'webgen/node'
require 'webgen/tree'

class TestTagTikz < MiniTest::Unit::TestCase

  def test_call
    website, context = Test.setup_tag_test
    website.ext.path_handler = MiniTest::Mock.new

    website.expect(:tree, Webgen::Tree.new(website))
    root = Webgen::Node.new(website.tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'file.page', '/file.html')
    tikz_node = Webgen::Node.new(root, 'test.png', '/test.png')
    context[:chain] = [node]

    body = '\tikz \draw (0,0) -- (0,1);'
    website.ext.path_handler.expect(:create_secondary_nodes, [tikz_node],
                                    [Webgen::Path.new('/test.png'), body, 'copy', '/file.page'])
    assert_tag_result(context, '<img src="test.png" alt="" />',
                      body, 'test.png', [], '', '72 72', false, {})
    website.ext.path_handler.verify

    website.ext.path_handler.expect(:create_secondary_nodes, [tikz_node],
                                    [Webgen::Path.new('/images/test.png'), body, 'copy', '/file.page'])
    assert_tag_result(context, '<img src="test.png" alt="title" />',
                      body, 'images/test.png', ['arrows'], '->', '72 72', true, {'alt' => 'title'})
    website.ext.path_handler.verify

  end

  def assert_tag_result(context, result, body, path, libs, opts, res, trans, imgattr)
    context[:config] = {'tag.tikz.path' => path, 'content_processor.tikz.libraries' => libs,
      'content_processor.tikz.opts' => opts, 'content_processor.tikz.resolution' => res,
      'content_processor.tikz.transparent' => trans, 'tag.tikz.img_attr' => imgattr}
    assert_equal(result, Webgen::Tag::Tikz.call('tikz', body, context))
  end

end
