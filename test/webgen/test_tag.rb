# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tag'
require 'webgen/configuration'

class Webgen::Tag::MyTag

  def self.call(tag, body, context)
    "#{tag}#{body}#{context[:config]['tag.my_tag.opt']}"
  end

end


class TestTag < Minitest::Test

  include Webgen::TestHelper

  def setup
    @config = Webgen::Configuration.new
    setup_website(@config)

    @tag = Webgen::Tag.new(@website)
  end

  def test_register
    check_tdata = lambda do |tdata, callable,  config_prefix, mandatory_options, initialized|
      assert_equal(callable, tdata.object)
      assert_equal(config_prefix, tdata.config_prefix)
      assert_equal(mandatory_options, tdata.mandatory)
      assert_equal(initialized, tdata.initialized)
    end

    @tag.register('Webgen::Tag::MyTag')
    check_tdata.call(@tag.registered_extensions[:my_tag],
                     'Webgen::Tag::MyTag', 'tag.my_tag', [], false)
    assert(@tag.registered?('my_tag'))

    @tag.register('MyTag', :names => ['mytag', 'other'])
    check_tdata.call(@tag.registered_extensions[:my_tag],
                     'Webgen::Tag::MyTag', 'tag.my_tag', [], false)
    assert(@tag.registered?('my_tag'))
    assert(@tag.registered?('other'))

    assert_raises(ArgumentError) { @tag.register('doit') {} }
    @tag.register('doit', :config_prefix => 'other') do |tag, body, context|
      'doit: now'
    end
    assert(@tag.registered?('doit'))

    @tag.register('MyTag', :names => ['other'], :config_prefix => 'other', :mandatory => ['mandatory'])
    check_tdata.call(@tag.registered_extensions[:other],
                     'Webgen::Tag::MyTag', 'other', ['mandatory'], false)
  end

  def test_call
    @config.define_option('tag.my_tag.opt', 'param1') {|v| raise "Error" unless v.kind_of?(String) || v.kind_of?(Array); [v].flatten.join('')}
    @config.freeze
    @website.logger.level = Logger::WARN

    context = Webgen::Context.new(@website)

    assert_raises(Webgen::RenderError) { @tag.call('unknown', {}, 'body', context) }

    @tag.register('MyTag', :mandatory => ['mandatory'])
    assert_raises(Webgen::RenderError) { @tag.call('my_tag', {}, 'body', context) }

    @tag.register('MyTag')
    assert_raises(Webgen::RenderError) { @tag.call('my_tag', Class.new, 'body', context) }
    assert_raises(Webgen::Configuration::Error) { @tag.call('my_tag', {'opt' => :value}, 'body', context) }


    @tag.register('MyTag')
    result = @tag.call('my_tag', nil, 'body', context)
    assert_equal('my_tagbodyparam1', result)
    assert_nothing_logged

    result = @tag.call('my_tag', {'opt' => 'value'}, 'body', context)
    assert_equal('my_tagbodyvalue', result)
    assert_nothing_logged
    assert_nil(context[:config])

    result = @tag.call('my_tag', {'tag.my_tag.opt' => 'value1', 'unknown' => 'unknown'}, 'body', context)
    assert_equal('my_tagbodyvalue1', result)
    assert_log_match(/Invalid configuration option 'unknown'/)

    result = @tag.call('my_tag', 'unknown', 'body', context)
    assert_equal('my_tagbodyparam1', result)
    assert_log_match(/No default mandatory option/)


    @tag.register('MyTag', :mandatory => ['opt'])
    assert_raises(Webgen::RenderError) { @tag.call('my_tag', {}, 'body', context) }

    result = @tag.call('my_tag', 'unknown', 'body', context)
    assert_equal('my_tagbodyunknown', result)

    result = @tag.call('my_tag', ['unknown'], 'body', context)
    assert_equal('my_tagbodyunknown', result)
  end

  def test_replace_tags
    @config.define_option('tag.prefix', '')
    @config.freeze

    assert_raises(NoMethodError) { @tag.replace_tags("{test:}") }
    @website.blackboard.dispatch_msg(:website_initialized)

    @tag.replace_tags("{test: {param: value}}") do |tag, params, body|
      assert_equal('test', tag)
      assert_equal({'param' => 'value'}, params)
      assert_equal('', body)
    end
  end

  def test_class_render_tag_template
    @website.ext.content_processor = Webgen::ContentProcessor.new
    context = Webgen::Context.new(@website)
    context[:config] = {'tag.tag.template' => '/tag.template'}

    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    template = RenderNode.new("--- name:tag.tag\nnothing", root, 'tag.template', '/tag.template')
    context[:chain] = [template]

    assert_equal('nothing', Webgen::Tag.render_tag_template(context, 'tag'))
  end

end
