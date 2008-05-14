require 'test/unit'
require 'webgen/contentprocessor/context'

class TestContentProcessorContext < Test::Unit::TestCase

  def setup
    @context = Webgen::ContentProcessor::Context.new('test', :key => :value, :chain => [:first, :last])
  end

  def test_clone
    other = @context.clone(:content => 'new', :key => :other)
    assert_equal('new', other.content)
    assert_equal(:other, other[:key])
    assert_equal([:first, :last], other[:chain])
  end

  def test_accessors
    assert_equal('test', @context.content)
    assert_equal({:key => :value, :chain => [:first, :last]}, @context.options)
    assert_equal(:first, @context.ref_node)
    assert_equal(:last, @context.content_node)
    assert_equal(:value, @context[:key])
    @context[:key] = :newvalue
    assert_equal(:newvalue, @context[:key])
  end

end
