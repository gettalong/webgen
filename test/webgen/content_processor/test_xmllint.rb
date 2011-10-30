# -*- encoding: utf-8 -*-

require 'helper'
require 'stringio'
require 'logger'
require 'webgen/content_processor/xmllint'

class TestXmllint < MiniTest::Unit::TestCase

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    cp = Webgen::ContentProcessor::Xmllint

    begin
      tmp, ENV['PATH'] = ENV['PATH'], '/sbin'
      assert_raises(Webgen::CommandNotFoundError) { cp.call(context) }
    ensure
      ENV['PATH'] = tmp
    end

    output = StringIO.new('')
    logger = ::Logger.new(output)
    logger.level = Logger::WARN
    website.expect(:logger, logger)
    website.expect(:config, {'content_processor.xmllint.options' => ''})

    context.content = data = 'test'
    assert_equal(data, cp.call(context).content)
    output.rewind; assert_match(/<\/test:~1>/, output.read)

    output.string = ''
    context.content = data = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' +
      '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>title</title></head><body></body></html>'
    assert_equal(data, cp.call(context).content)
    assert_equal(0, output.string.length)
  end

end
