# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tag'

class TestTagCoderay < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::Coderay.new
  end

  def call(context, body, lang, process)
    @obj.set_params({'tag.coderay.lang' => lang,
                      'tag.coderay.process' => process})
    result = @obj.call('coderay', body, context)
    @obj.set_params({})
    result
  end

  def test_call
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/', {'title' => 'Hallo'})
    context = Webgen::Context.new(:chain => [root])

    assert(call(context, 'TestData', 'html', false).include?('TestData'))
    assert(call(context, '{title:}', :ruby, true).include?('Hallo'))
  end

end
