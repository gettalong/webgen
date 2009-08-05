# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/contentprocessor'

class TestContentProcessorXmllint < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_call
    obj = Webgen::ContentProcessor::Xmllint.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, '/test', 'test')
    context = Webgen::Context.new(:content => "", :chain => [node])

    tmp, ENV['PATH'] = ENV['PATH'], '/sbin'
    assert_raise(Webgen::CommandNotFoundError) { obj.call(context) }
    ENV['PATH'] = tmp

    output = StringIO.new('')
    @website.logger = ::Logger.new(output)
    @website.logger.level = Logger::WARN

    context.content = data = 'test'
    obj.call(context)
    assert_equal(data, context.content)
    output.rewind; assert_match(/<\/test:~1>/, output.read)

    output.string = ''
    context.content = data = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' +
      '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>title</title></head><body></body></html>'
    obj.call(context)
    assert_equal(data, context.content)
    assert_equal(0, output.string.length)
  end

end
