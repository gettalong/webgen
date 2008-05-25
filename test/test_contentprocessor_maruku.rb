require 'test/unit'
require 'webgen/contentprocessor'

class TestContentProcessorMaruku < Test::Unit::TestCase

  def test_call
    @obj = Webgen::ContentProcessor::Maruku.new
    context = Webgen::ContentProcessor::Context.new(:content => '# header')
    assert_equal('<h1 id=\'header\'>header</h1>', @obj.call(context).content)

    context.content = "# head*d* {#das .dsaf "
    assert_raise(RuntimeError) { @obj.call(context)}
  end

end
