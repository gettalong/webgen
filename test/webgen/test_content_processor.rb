# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/content_processor'

class Webgen::ContentProcessor::MyProcessor

  def self.call(context)
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
    assert(@cp.registered?('my_processor'))
    refute(@cp.is_binary?('my_processor'))

    @cp.register('MyProcessor')
    assert(@cp.registered?('my_processor'))
    refute(@cp.is_binary?('my_processor'))

    @cp.register('MyProcessor', :type => :binary, :name => 'test', :ext_map => {:a => :b})
    assert(@cp.registered?('test'))
    assert(@cp.is_binary?('test'))
    assert_equal({:a => :b}, @cp.extension_map('test'))
    assert_equal({:a => :b}, @cp.extension_map)
    assert_equal([:test, :b], @cp.map_extension(:a))
    assert_nil(@cp.map_extension(:b))

    @cp.register('doit') do |context|
      context.content = 'Nothing left.'
    end
    assert(@cp.registered?('doit'))
    refute(@cp.is_binary?('doit'))
  end

  def test_is_binary
    @cp.register('MyProcessor', :type => :text)
    refute(@cp.is_binary?('m_yprocessor'))
    @cp.register('MyProcessor', :type => :binary)
    assert(@cp.is_binary?('my_processor'))
    refute(@cp.is_binary?('unknown contentprocessor'))
  end

  def test_call
    @cp.register('MyProcessor')
    @cp.register('Webgen::ContentProcessor::MyProcessor', :name => 'other')
    @cp.register('doit') do |context|
      raise 'msg' if context == 'error'
      context + 'value'
    end

    assert_equal('valuevalue', @cp.call('my_processor', 'value'))
    assert_equal('valuevalue', @cp.call('other', 'value'))
    assert_equal('valuevalue', @cp.call('doit', 'value'))

    s = 'webgen'
    def s.dest_node; "dest_node"; end
    assert_raises(Webgen::Error) { @cp.call('my_processor', s) }

    s = 'error'
    def s.dest_node; "dest_node"; end
    assert_raises(Webgen::RenderError) { @cp.call('my_processor', s) }
    assert_raises(Webgen::RenderError) { @cp.call('doit', s) }
  end

  def test_normalize_pipeline
    @cp.register('MyProcessor')
    @cp.register('MyProcessor', :name => 'other')
    assert_equal(['my_processor', 'other', 'other'], @cp.normalize_pipeline('my_processor,other,other'))
    assert_equal(['my_processor', 'other', 'other'], @cp.normalize_pipeline('my_processor, other, other'))
    assert_equal(['my_processor', 'other', 'other'], @cp.normalize_pipeline(['my_processor','other','other']))

    assert_raises(Webgen::Error) { @cp.normalize_pipeline('unknown') }
  end

end
