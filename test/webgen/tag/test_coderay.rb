# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/context'
require 'webgen/tag/coderay'
require 'webgen/node'
require 'webgen/tree'

class TestTagCoderay < MiniTest::Unit::TestCase

  def test_call
    website, @context = Test.setup_tag_test
    website.ext.content_processor = MiniTest::Mock.new
    website.ext.content_processor.expect(:call, @context, ['tags', @context])
    website.expect(:tree, Webgen::Tree.new(website))
    root = Webgen::Node.new(website.tree.dummy_root, '/', '/', {'title' => 'Hallo'})
    @context[:chain] = [root]

    assert_result_includes('TestData', @context, 'TestData', 'html', false, 'style')
    @context.content = 'Hallo'
    assert_result_includes('Hallo', @context, '{title:}', :ruby, true, 'other')
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
