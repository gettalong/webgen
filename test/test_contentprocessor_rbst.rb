# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/websiteaccess'
require 'webgen/contentprocessor'

class TestContentProcessorRbST < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_call
    @obj = Webgen::ContentProcessor::RbST.new
    node = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    context = Webgen::Context.new(:content => "=====\nTest\n=====", :chain => [node])
    assert_equal("<div class=\"document\" id=\"test\">\n<h1 class=\"title\">Test</h1>\n</div>", @obj.call(context).content)

    def @obj.require(lib); raise LoadError; end
    assert_raise(Webgen::LoadError) { @obj.call(context) }
  end

end
