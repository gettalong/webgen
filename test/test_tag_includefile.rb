require 'test/unit'
require 'helper'
require 'fileutils'
require 'tempfile'
require 'webgen/tag'

class TestTagIncludeFile < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::IncludeFile.new
  end

  def call(context, filename, process, escape)
    @obj.set_params({'tag.includefile.filename' => filename,
                      'tag.includefile.process_output' => process,
                      'tag.includefile.escape_html' => escape})
    result = @obj.call('include_file', '', context)
    @obj.set_params({})
    result
  end

  def test_call
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    context = Webgen::ContentProcessor::Context.new(:chain => [root])

    content = "<a>This is 'a' Test</a>"
    file = Tempfile.new('webgen-test-file')
    file.write(content)
    file.close

    assert_equal([content, false], call(context, file.path, false, false))
    assert_equal([content, true], call(context, file.path, true, false))
    assert_equal([CGI::escapeHTML(content), true], call(context, file.path, true, true))
    assert_raise(Errno::ENOENT) { call(context, 'invalidfile', true, true) }

    root.dirty = false
    @website.blackboard.dispatch_msg(:node_changed?, root)
    assert(!root.dirty)

    File.utime(Time.now + 1, Time.now + 1, file.path)
    @website.blackboard.dispatch_msg(:node_changed?, root)
    assert(root.dirty)
  end

end
