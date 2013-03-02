# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/tidy'

class TestTidy < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_static_call
    require 'webgen/content_processor/tidy' rescue skip($!.message)

    setup_context
    @website.config['content_processor.tidy.options'] = ''
    cp = Webgen::ContentProcessor::Tidy

    begin
      cp.call(@context)
    rescue Webgen::CommandNotFoundError
      skip("Binary tidy not found")
    end

    begin
      tmp, ENV['PATH'] = ENV['PATH'], '/sbin'
      assert_raises(Webgen::CommandNotFoundError) { cp.call(@context) }
    ensure
      ENV['PATH'] = tmp
    end

    @context.content = "testcontent"
    assert_match(/html.*testcontent/im, cp.call(@context).content)
    assert_log_match(/inserting missing/)

    @context.content = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2//EN"><html><head><title>t</title></head><body>b</body></html'
    assert_match(/body.*b.*body/im, cp.call(@context).content)
    assert_equal(0, @logio.string.length)
  end

end
