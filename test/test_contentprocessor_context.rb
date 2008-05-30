require 'test/unit'
require 'helper'
require 'webgen/contentprocessor/context'

class TestContentProcessorContext < Test::Unit::TestCase

  def setup
    @context = Webgen::ContentProcessor::Context.new(:content => 'test', :key => :value, :chain => [:first, :last])
  end

  def test_initialize
    context = Webgen::ContentProcessor::Context.new
    assert_equal('', context.content)
    assert_kind_of(Webgen::ContentProcessor::AccessHash, context[:processors])
  end

  def test_clone
    other = @context.clone(:content => 'new', :key => :other)
    assert_equal('new', other.content)
    assert_equal(:other, other[:key])
    assert_equal([:first, :last], other[:chain])
  end

  def test_accessors
    assert_equal(:value, @context[:key])
    assert_equal([:first, :last], @context[:chain])
    assert_equal('test', @context.content)
    assert_equal(:first, @context.ref_node)
    assert_equal(:last, @context.content_node)
    assert_equal(:value, @context[:key])
    @context[:key] = :newvalue
    assert_equal(:newvalue, @context[:key])
    assert_equal(:last, @context.dest_node)
    @context[:dest_node] = :other
    assert_equal(:other, @context.dest_node)
  end

end
