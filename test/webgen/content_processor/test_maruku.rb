# -*- encoding: utf-8 -*-

require 'webgen/test_helper'

class TestMaruku < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def setup
    require 'webgen/content_processor/maruku' rescue skip('Library maruku not installed')
    setup_context
    @cp = Webgen::ContentProcessor::Maruku
  end

  def test_static_call
    @context.content = '# header'
    assert_equal('<h1 id=\'header\'>header</h1>', @cp.call(@context).content)

    @context.content = "# head*d* {#das .dsaf "
    assert_raises(MaRuKu::Exception) { @cp.call(@context) }
  end

  def test_static_call_fix_for_invalid_id
    @context.content = '# `test`'
    assert_equal('<h1 id=\'id1\'><code>test</code></h1>', @cp.call(@context).content)
    @context.content = '# `test`'
    assert_equal('<h1 id=\'id1\'><code>test</code></h1>', @cp.call(@context).content)
  end

end
