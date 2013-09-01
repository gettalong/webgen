# -*- encoding: utf-8 -*-

require 'webgen/test_helper'

class TestXmllint < Minitest::Test

  include Webgen::TestHelper

  def test_static_call
    require 'webgen/content_processor/xmllint' rescue skip($!.message)

    setup_context
    @website.config['content_processor.xmllint.options'] = ''
    cp = Webgen::ContentProcessor::Xmllint

    begin
      cp.call(@context)
    rescue Webgen::CommandNotFoundError
      skip("Binary xmllint not found")
    end

    begin
      tmp, ENV['PATH'] = ENV['PATH'], '/sbin'
      assert_raises(Webgen::CommandNotFoundError) { cp.call(@context) }
    ensure
      ENV['PATH'] = tmp
    end

    @context.content = data = 'test'
    assert_equal(data, cp.call(@context).content)
    assert_log_match(/<\/test:~1>/)

    @context.content = data = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' +
      '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>title</title></head><body></body></html>'
    assert_equal(data, cp.call(@context).content)
    assert_equal(0, @logio.string.length)
  end

end
