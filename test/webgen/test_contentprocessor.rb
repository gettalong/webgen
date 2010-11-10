# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/contentprocessor'

class Webgen::ContentProcessor::MyProcessor

  def call(context)
    context + 'value'
  end

end

class TestContentProcessor < MiniTest::Unit::TestCase

  def test_class_register
    Webgen::ContentProcessor.register('MyProcessor')
    assert Webgen::ContentProcessor.registered?('myprocessor')
    refute Webgen::ContentProcessor.is_binary?('myprocessor')

    Webgen::ContentProcessor.register('MyProcessor', type: :binary, short_name: 'test')
    assert Webgen::ContentProcessor.registered?('test')
    assert Webgen::ContentProcessor.is_binary?('test')

     Webgen::ContentProcessor.register('doit') do |context|
      context.content = 'Nothing left.'
    end
    assert Webgen::ContentProcessor.registered?('doit')
    refute Webgen::ContentProcessor.is_binary?('doit')
  end

  def test_class_short_names
    assert_kind_of Array, Webgen::ContentProcessor.short_names
    refute_empty Webgen::ContentProcessor.short_names.sort
  end

  def test_class_registered
    assert Webgen::ContentProcessor.registered?('kramdown')
    refute Webgen::ContentProcessor.registered?('unknown contentprocessor')
  end

  def test_class_is_binary
    Webgen::ContentProcessor.register('MyProcessor', type: :binary, short_name: 'test')
    refute Webgen::ContentProcessor.is_binary?('kramdown')
    assert Webgen::ContentProcessor.is_binary?('test')
    refute Webgen::ContentProcessor.is_binary?('unknown contentprocessor')
  end

  def test_class_call
    Webgen::ContentProcessor.register('MyProcessor')
    Webgen::ContentProcessor.register('Webgen::ContentProcessor::MyProcessor', short_name: 'other')
    Webgen::ContentProcessor.register('doit') do |context|
      context + 'value'
    end

    assert_equal 'valuevalue', Webgen::ContentProcessor.call('myprocessor', 'value')
    assert_equal 'valuevalue', Webgen::ContentProcessor.call('other', 'value')
    assert_equal 'valuevalue', Webgen::ContentProcessor.call('doit', 'value')
  end

end
