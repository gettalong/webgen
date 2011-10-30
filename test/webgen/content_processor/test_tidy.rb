# -*- encoding: utf-8 -*-

require 'helper'
require 'stringio'
require 'logger'
require 'webgen/content_processor/tidy'

class TestTidy < MiniTest::Unit::TestCase

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    cp = Webgen::ContentProcessor::Tidy

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
    website.expect(:config, {'content_processor.tidy.options' => ''})

    context.content = "testcontent"
    assert_match(/html.*testcontent/im, cp.call(context).content)
    output.rewind; assert_match(/inserting missing/, output.read)

    output.string = ''
    context.content = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2//EN"><html><head><title>t</title></head><body>b</body></html'
    assert_match(/body.*b.*body/im, cp.call(context).content)
    assert_equal(0, output.string.length)
  end

end
