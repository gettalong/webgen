require 'test/unit'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorRDiscount < Test::Unit::TestCase

  def test_call
    @obj = Webgen::ContentProcessor::RDiscount.new
    node = Webgen::Node.new(Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/'), 'test', 'test')
    context = Webgen::ContentProcessor::Context.new(:content => '# header', :chain => [node])
    assert_equal("<h1>header</h1>\n", @obj.call(context).content)
  end

end
