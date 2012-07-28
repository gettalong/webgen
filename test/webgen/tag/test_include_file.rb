# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tag/include_file'
require 'fileutils'
require 'tempfile'

class TestTagIncludeFile < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_call
    setup_context

    content = "<a>This is 'a' Test</a>"
    file = Tempfile.new('webgen-test-file')
    file.write(content)
    file.close

    assert_tag_result([content, false], file.path, false, false)
    assert_tag_result([content, true], file.path, true, false)
    assert_tag_result([CGI::escapeHTML(content), true], file.path, true, true)

    @context[:config]['tag.include_file.filename'] = 'invalidfile'
    assert_raises(Webgen::RenderError) { Webgen::Tag::IncludeFile.call('include_file', '', @context) }
  end

  def assert_tag_result(result, filename, process, escape)
    @context[:config] = {'tag.include_file.filename' => filename,
      'tag.include_file.process_output' => process,
      'tag.include_file.escape_html' => escape}
    assert_equal(result, Webgen::Tag::IncludeFile.call('include_file', '', @context))
  end

end
