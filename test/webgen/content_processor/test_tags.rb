# -*- encoding: utf-8 -*-

require 'helper'
require 'stringio'
require 'logger'
require 'webgen/content_processor/tags'
require 'webgen/utils/tag_parser'

class TestContentProcessorTags < MiniTest::Unit::TestCase

  class SimpleTag

    def set_block(&block)
      @block = block
    end

    def call(tag, params, body, context)
      @block.call(tag, params, body, context)
    end

    def replace_tags(content, &block)
      Webgen::Utils::TagParser.new.replace_tags(content, &block)
    end

  end

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    context.content = '{test: }'
    stag = SimpleTag.new
    website.ext.tag = stag
    website.expect(:logger, Logger.new(StringIO.new))
    cp = Webgen::ContentProcessor::Tags

    stag.set_block do |tag, params, body, local_context|
      assert_equal('test', tag)
      assert_equal(nil, params)
      assert_equal('', body)
      assert_equal(context, local_context)
    end
    cp.call(context)

    website.verify
  end

end
