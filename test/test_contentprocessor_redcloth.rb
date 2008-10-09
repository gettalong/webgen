require 'test/unit'
require 'webgen/websiteaccess'
require 'webgen/contentprocessor'

class TestContentProcessorRedCloth < Test::Unit::TestCase

  def test_call
    @obj = Webgen::ContentProcessor::RedCloth.new
    context = Webgen::ContentProcessor::Context.new(:content => 'h1. header')
    assert_equal('<h1>header</h1>', @obj.call(context).content)
  end

end
