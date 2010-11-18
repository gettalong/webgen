# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/content_processor'

class Webgen::ContentProcessor::MyProcessor

  def call(context)
    raise Webgen::Error.new('msg') if context == 'webgen'
    raise 'msg' if context == 'error'
    context + 'value'
  end

end

class TestContentProcessor < MiniTest::Unit::TestCase

  def setup
    @cp = Webgen::ContentProcessor.new
  end

  def test_register
    @cp.register('Webgen::ContentProcessor::MyProcessor')
    assert(@cp.registered?('myprocessor'))
    refute(@cp.is_binary?('myprocessor'))

    @cp.register('MyProcessor')
    assert(@cp.registered?('myprocessor'))
    refute(@cp.is_binary?('myprocessor'))

    @cp.register('MyProcessor', :type => :binary, :short_name => 'test')
    assert(@cp.registered?('test'))
    assert(@cp.is_binary?('test'))

    @cp.register('doit') do |context|
      context.content = 'Nothing left.'
    end
    assert(@cp.registered?('doit'))
    refute(@cp.is_binary?('doit'))
  end

  def test_short_names
    assert_kind_of(Array, @cp.short_names)
    assert_empty(@cp.short_names.sort)
    @cp.register('MyProcessor')
    assert_equal(['myprocessor'], @cp.short_names)
  end

  def test_registered
    refute(@cp.registered?('myprocessor'))
    @cp.register('MyProcessor')
    assert(@cp.registered?('myprocessor'))
  end

  def test_is_binary
    @cp.register('MyProcessor', :type => :text)
    refute(@cp.is_binary?('myprocessor'))
    @cp.register('MyProcessor', :type => :binary)
    assert(@cp.is_binary?('myprocessor'))
    refute(@cp.is_binary?('unknown contentprocessor'))
  end

  def test_call
    @cp.register('MyProcessor')
    @cp.register('Webgen::ContentProcessor::MyProcessor', short_name: 'other')
    @cp.register('doit') do |context|
      raise 'msg' if context == 'error'
      context + 'value'
    end

    assert_equal('valuevalue', @cp.call('myprocessor', 'value'))
    assert_equal('valuevalue', @cp.call('other', 'value'))
    assert_equal('valuevalue', @cp.call('doit', 'value'))

    assert_raises(Webgen::Error) { @cp.call('myprocessor', 'webgen') }
    s = 'error'
    def s.dest_node; 'dest_node'; end
    def s.ref_node; 'ref_node'; end
    assert_raises(Webgen::RenderError) { @cp.call('myprocessor', s) }
    assert_raises(Webgen::RenderError) { @cp.call('doit', s) }
  end

  def test_static_content_processor
    static = Webgen::ContentProcessor.static
    assert_kind_of(Webgen::ContentProcessor, static)
    assert(static.registered?('kramdown'))
  end

  def test_clone
    static = Webgen::ContentProcessor.static
    cloned = static.clone
    cloned.register('MyProcessor')
    refute(static.registered?('myprocessor'))
  end

end
