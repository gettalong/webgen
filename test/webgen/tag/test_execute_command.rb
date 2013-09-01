# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tag/execute_command'
require 'time'

class TestTagExecuteCommand < Minitest::Test

  include Webgen::TestHelper

  def test_call
    setup_context

    test_text = "a\"b\""
    assert_tag_result([test_text, false], echo_cmd(test_text), false, false)
    assert_tag_result([test_text, true], echo_cmd(test_text), true, false)
    assert_tag_result(['a&quot;b&quot;', true], echo_cmd(test_text), true, true)
    assert_tag_result(['a&quot;b&quot;', true], echo_cmd(test_text), true, true)

    @context[:config]['tag.execute_command.command'] = 'invalid_echo_command'
    assert_raises(Webgen::RenderError) { Webgen::Tag::ExecuteCommand.call('execute_cmd', '', @context) }
  end

  def assert_tag_result(result, command, process, escape)
    @context[:config] = {'tag.execute_command.command' => command,
      'tag.execute_command.process_output' => process,
      'tag.execute_command.escape_html' => escape}
    retval = Webgen::Tag::ExecuteCommand.call('execute_cmd', '', @context)
    assert_equal(result, [retval.first.chomp.strip, retval.last])
  end

  def echo_cmd(data)
    (RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ?  "echo #{data}" : "echo '#{data}'")
  end

end
