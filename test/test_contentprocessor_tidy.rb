# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/contentprocessor'

class TestContentProcessorTidy < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_call
    obj = Webgen::ContentProcessor::Tidy.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, '/test', 'test')
    context = Webgen::Context.new(:content => "testcontent", :chain => [node])

    tmp, ENV['PATH'] = ENV['PATH'], '/sbin'
    assert_raise(Webgen::CommandNotFoundError) { obj.call(context) }
    ENV['PATH'] = tmp

    output = StringIO.new('')
    @website.logger = ::Logger.new(output)
    @website.logger.level = Logger::WARN

    assert_match(/html.*testcontent/im, obj.call(context).content)
    output.rewind; assert_match(/inserting missing/, output.read)

    output.string = ''
    context.content = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2//EN"><html><head><title>t</title></head><body>b</body></html'
    assert_match(/body.*b.*body/im, obj.call(context).content)
    assert_equal(0, output.string.length)
  end

end
