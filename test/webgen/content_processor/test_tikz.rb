# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/tikz'

class TestContentProcessorTikz < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_static_call
    setup_context
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Blocks')
    @website.ext.content_processor.register('Erb')
    template_data = File.read(File.join(Webgen::Utils.data_dir, 'passive_sources', 'templates', 'tikz.template'))
    node = RenderNode.new(template_data, @website.tree.dummy_root, '/template', '/template')

    @context.node.expect(:[], nil, ['ignored'])

    call('\tikz \draw (0,0) -- (0,1);', 'test.png', [], '', '72 72', false)
    refute_nil(@context.content)

    assert_raises(Webgen::RenderError) { call('\tikz \asdfasdfasf', 'test.png', [], '', '72 72', false) }

    call('\tikz \draw (0,0) -- (0,1);', '/images/test.gif', ['arrows'], '->', '72 72', true)
    refute_nil(@context.content)
  end

  def call(content, path, libs, opts, res, trans)
    @context.content = content
    @context.dest_node.expect(:dest_path, path)
    @context.website.config.update('content_processor.tikz.resolution' => res,
                                   'content_processor.tikz.transparent' => trans,
                                   'content_processor.tikz.libraries' => libs,
                                   'content_processor.tikz.opts' => opts,
                                   'content_processor.tikz.template' => '/template')
    Webgen::ContentProcessor::Tikz.call(@context)
  end

end
