# -*- encoding: utf-8 -*-

require 'webgen/test_helper'

class TestTagCoderay < Minitest::Test

  include Webgen::TestHelper

  def test_call
    require 'webgen/tag/coderay' rescue skip("Library coderay not installed")

    setup_context
    @website.ext.content_processor = Object.new
    @website.ext.content_processor.define_singleton_method(:call) {|_, context| context}
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/', {'title' => 'Hallo'})
    @context[:chain] = [root]

    assert_result_includes('TestData', @context, 'TestData', 'html', false, 'style')
    assert_result_includes('title', @context, '{title:}', :ruby, true, 'other')
    assert_result_includes('class="constant"', @context, 'TestData', 'ruby', false, 'other')
  end

  def assert_result_includes(string, context, body, lang, process, css)
    @context[:config] = {'tag.coderay.lang' => lang,
      'tag.coderay.process_body' => process,
      'tag.coderay.css' => css,
      'tag.coderay.wrap' => 'span',
      'tag.coderay.line_number_start' => 1,
      'tag.coderay.tab_width' => 8,
      'tag.coderay.bold_every' => 10}
    assert(Webgen::Tag::Coderay.call('coderay', body, @context).include?(string), "Result should include #{string}")
  end

end
