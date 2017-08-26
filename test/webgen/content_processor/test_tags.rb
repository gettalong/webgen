# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/tags'
require 'webgen/utils/tag_parser'

class TestContentProcessorTags < Minitest::Test

  include Webgen::TestHelper

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
    setup_context
    cp = Webgen::ContentProcessor::Tags

    @context.content = '{test: }'
    stag = SimpleTag.new
    @website.ext.tag = stag

    stag.set_block do |tag, params, body, local_context|
      assert_equal('test', tag)
      assert_nil(params)
      assert_equal('', body)
      assert_equal(@context, local_context)
    end
    cp.call(@context)
  end

end
