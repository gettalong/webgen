# -*- encoding: utf-8 -*-

require 'timeout'
require 'webgen/test_helper'

class TestContentProcessorTikz < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    require 'webgen/content_processor/tikz' rescue skip($!.message)

    setup_context
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Blocks')
    @website.ext.content_processor.register('Erb')
    template_data = File.read(File.join(Webgen::Utils.data_dir, 'passive_sources', 'templates', 'tikz.template'))
    RenderNode.new(template_data, @website.tree.dummy_root, '/template', '/template')

    @context.node.define_singleton_method(:[]) {|_ignored| nil}

    call('\tikz \draw (0,0) -- (1,1);', 'test.png', [], '', '72 72', false)
    Timeout.timeout(0.2) { call('\tikz \draw (0,0) -- (1,1);', 'test.png', [], '', '72 72', false) } # test cache
    refute_nil(@context.content)

    assert_raises(Webgen::RenderError) { call('\tikz \asdfasdfasf', 'test.png', [], '', '72 72', false) }

    call('\tikz \draw (0,0) -- (1,1);', '/images/test.gif', ['arrows'], '->', '72 72', true)
    refute_nil(@context.content)
  end

  def call(content, path, libs, opts, res, trans)
    @context.content = content
    if @context.dest_node.singleton_class.method_defined?(:dest_path)
      @context.dest_node.singleton_class.send(:remove_method, :dest_path)
    end
    @context.dest_node.define_singleton_method(:dest_path) {path}
    @context.website.config.update('content_processor.tikz.resolution' => res,
                                   'content_processor.tikz.transparent' => trans,
                                   'content_processor.tikz.libraries' => libs,
                                   'content_processor.tikz.opts' => opts,
                                   'content_processor.tikz.template' => '/template',
                                   'content_processor.tikz.engine' => 'pdflatex')
    Webgen::ContentProcessor::Tikz.call(@context)
  end

  def teardown
    #FileUtils.rm_rf(@website.directory) if @website
  end

end
