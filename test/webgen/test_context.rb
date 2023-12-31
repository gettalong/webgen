# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/context'

class TestContext < Minitest::Test

  include Webgen::TestHelper

  module TestModule
    def hallo
      "hallo"
    end
  end

  def setup
    setup_website
    @context = Webgen::Context.new(@website, :content => 'test', :key => :value, :chain => [:first, :last])
  end

  def test_initialize
    @website.ext.context_modules = [TestModule];
    context = Webgen::Context.new(@website)
    assert_equal('', context.content)
    assert_equal({}, context.persistent)
    assert_same(@website.object_id, context.website.object_id)
    assert_equal('hallo', context.hallo)

    context = Webgen::Context.new(@website, :content => 'test', :key => :value)
    assert_equal('test', context.content)
    assert_equal(:value, context[:key])
    assert_equal({}, context.persistent)

    context = Webgen::Context.new(@website, {:content => 'test', :key => :value}, {:other => :val})
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
    context = Webgen::Context.new(@website)
    tag = Minitest::Mock.new
    tag.expect(:call, 'value', ['mytag', {'opt' => 'val'}, 'body', context])
    @website.ext.tag = tag

    assert_equal('value', context.tag('mytag', {'opt' => 'val'}, 'body'))
    tag.verify
  end

  def test_html_head_methods
    @context.html_head.inline_fragment(:css, "content")
    @context.html_head.inline_fragment(:js, "content")
    @context.html_head.meta('name', 'content')
    @context.html_head.meta_property('property', 'content')

    assert_equal(['content'], @context.persistent[:cp_html_head][:css_inline])
    assert_equal(['content'], @context.persistent[:cp_html_head][:js_inline])
    assert_equal({'name' => 'content'}, @context.persistent[:cp_html_head][:meta])
    assert_equal({'property' => 'content'}, @context.persistent[:cp_html_head][:meta_property])
  end

end
