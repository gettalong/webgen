# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/content_processor/maruku'

class TestMaruku < MiniTest::Unit::TestCase

  def test_static_call
    website, node, context = Test.setup_content_processor_test
    cp = Webgen::ContentProcessor::Maruku

    context.content = '# header'
    assert_equal('<h1 id=\'header\'>header</h1>', cp.call(context).content)

    context.content = "# head*d* {#das .dsaf "
    assert_raises(MaRuKu::Exception) { cp.call(context) }
  end

  def test_static_call_fix_for_invalid_id
    website, node, context = Test.setup_content_processor_test
    cp = Webgen::ContentProcessor::Maruku

    context.content = '# `test`'
    assert_equal('<h1 id=\'id1\'><code>test</code></h1>', cp.call(context).content)
    context.content = '# `test`'
    assert_equal('<h1 id=\'id1\'><code>test</code></h1>', cp.call(context).content)
  end

end
