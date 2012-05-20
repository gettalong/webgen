# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/content_processor/tikz'

class TestContentProcessorTikz < MiniTest::Unit::TestCase

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    website.expect(:config, {})
    node.expect(:[], nil, ['ignored'])

    call(context, '\tikz \draw (0,0) -- (0,1);', 'test.png', [], '', '72 72', false)
    refute_nil(context.content)

    assert_raises(Webgen::RenderError) { call(context, '\tikz \asdfasdfasf', 'test.png', [], '', '72 72', false) }

    call(context, '\tikz \draw (0,0) -- (0,1);', '/images/test.gif', ['arrows'], '->', '72 72', true)
    refute_nil(context.content)
  end

  def call(context, content, path, libs, opts, res, trans)
    context.content = content
    context.dest_node.expect(:dest_path, path)
    context.website.config.update('content_processor.tikz.resolution' => res,
                                  'content_processor.tikz.transparent' => trans,
                                  'content_processor.tikz.libraries' => libs,
                                  'content_processor.tikz.opts' => opts)
    Webgen::ContentProcessor::Tikz.call(context)
  end

end
