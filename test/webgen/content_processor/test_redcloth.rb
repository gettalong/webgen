# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/content_processor/redcloth'

class TestRedCloth < MiniTest::Unit::TestCase

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    website.expect(:config, {'content_processor.redcloth.hard_breaks' => false})
    cp = Webgen::ContentProcessor::RedCloth

    context.content = "h1. header\n\nthis\nis\nsome\ntext"
    assert_equal("<h1>header</h1>\n<p>this\nis\nsome\ntext</p>", cp.call(context).content)

    context.content = "h1. header\n\nthis\nis\nsome\ntext"
    website.config['content_processor.redcloth.hard_breaks'] = true
    assert_equal("<h1>header</h1>\n<p>this<br />\nis<br />\nsome<br />\ntext</p>", cp.call(context).content)
  end

end
