# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/context'

class TestContext < MiniTest::Unit::TestCase

  def setup
    @context = Webgen::Context.new(:website, :content => 'test', :key => :value, :chain => [:first, :last])
  end

  def test_initialize
    context = Webgen::Context.new(:website)
    assert_equal('', context.content)
    assert_equal({}, context.persistent)
    assert_equal(:website, context.website)

    context = Webgen::Context.new(:website, :content => 'test', :key => :value)
    assert_equal('test', context.content)
    assert_equal(:value, context[:key])
    assert_equal({}, context.persistent)

    context = Webgen::Context.new(:website, {:content => 'test', :key => :value}, {:other => :val})
    assert_equal('test', context.content)
    assert_equal(:value, context[:key])
    assert_equal({:other => :val}, context.persistent)
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
    @context[:key] = :newvalue
    assert_equal(:newvalue, @context[:key])
  end

  def test_node_methods
    assert_equal(:first, @context.ref_node)
    assert_equal(:last, @context.content_node)
    assert_equal(:last, @context.dest_node)
    @context[:dest_node] = :other
    assert_equal(:other, @context.dest_node)
  end

  def test_tags_methods
    tag = MiniTest::Mock.new
    ext = MiniTest::Mock.new
    website = MiniTest::Mock.new
    context = Webgen::Context.new(website)
    website.expect(:ext, ext)
    ext.expect(:tag, tag)
    tag.expect(:call, 'value', ['mytag', {'opt' => 'val'}, 'body', context])

    assert_equal('value', context.tag('mytag', {'opt' => 'val'}, 'body'))
    tag.verify
  end

  def test_render_methods
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    node.node_info[:page] = Webgen::Page.from_data("--- name:content\ndata\n--- name:other\nother")
    @context[:chain] = [root, node]

    assert_equal('data', @context.render_block('content'))
    assert_equal('other', @context.render_block(:name => 'other'))
  end

end
