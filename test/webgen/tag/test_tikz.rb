# -*- encoding: utf-8 -*-

require 'webgen/test_helper'

class TestTagTikz < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_call
    require 'webgen/tag/tikz' rescue skip($!.message)

    setup_context
    @website.ext.path_handler = MiniTest::Mock.new

    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'file.page', '/file.html')
    tikz_node = Webgen::Node.new(root, 'test.png', '/test.png')
    @context[:chain] = [node]

    body = '\tikz \draw (0,0) -- (0,1);'
    @website.ext.path_handler.expect(:create_secondary_nodes, [tikz_node],
                                    [Webgen::Path.new('/test.png'), body, '/file.page'])
    assert_tag_result('<img src="test.png" alt="" />',
                      body, 'test.png', [], '', '72 72', false, {})
    @website.ext.path_handler.verify

    @website.ext.path_handler.expect(:create_secondary_nodes, [tikz_node],
                                    [Webgen::Path.new('/images/test.png'), body, '/file.page'])
    assert_tag_result('<img src="test.png" alt="title" />',
                      body, 'images/test.png', ['arrows'], '->', '72 72', true, {'alt' => 'title'})
    @website.ext.path_handler.verify

  end

  def assert_tag_result(result, body, path, libs, opts, res, trans, imgattr)
    @context[:config] = {'tag.tikz.path' => path, 'content_processor.tikz.libraries' => libs,
      'content_processor.tikz.opts' => opts, 'content_processor.tikz.resolution' => res,
      'content_processor.tikz.transparent' => trans, 'tag.tikz.img_attr' => imgattr}
    assert_equal(result, Webgen::Tag::Tikz.call('tikz', body, @context))
  end

end
