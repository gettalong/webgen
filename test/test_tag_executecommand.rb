require 'test/unit'
require 'helper'
require 'webgen/tag'
require 'rbconfig'

class TestTagExecuteCommand < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::ExecuteCommand.new
  end

  def call(context, command, process, escape)
    @obj.set_params({'tag.executecommand.command' => command,
                      'tag.executecommand.process_output' => process,
                      'tag.executecommand.escape_html' => escape})
    result = @obj.call('execute_cmd', '', context)
    @obj.set_params({})
    [result.first.chomp.strip, result.last]
  end

  def test_call
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    context = Webgen::ContentProcessor::Context.new(:chain => [root])

    test_text = "a\"b\""
    assert_equal([test_text, false], call(context, echo_cmd(test_text), false, false))
    assert_equal([test_text, true], call(context, echo_cmd(test_text), true, false))
    assert_equal(['a&quot;b&quot;', true], call(context, echo_cmd(test_text), true, true))
    assert_equal(['a&quot;b&quot;', true], call(context, echo_cmd(test_text), true, true))
    assert_raise(RuntimeError) { call(context, 'invalid_echo_command', true, true) }
  end

  def echo_cmd(data)
    (Config::CONFIG['arch'].include?('mswin32') ?  "echo #{data}" : "echo '#{data}'")
  end

end
