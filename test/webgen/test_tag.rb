# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/tag'
require 'webgen/configuration'
require 'webgen/blackboard'
require 'webgen/context'
require 'stringio'
require 'logger'
require 'ostruct'

class Webgen::Tag::MyTag

  def self.call(tag, body, context)
    "#{tag}#{body}#{context[:config]['tag.my_tag.opt']}"
  end

end


class TestTag < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @config = Webgen::Configuration.new
    @blackboard = Webgen::Blackboard.new
    @website.expect(:config, @config)
    @website.expect(:blackboard, @blackboard)

    @tag = Webgen::Tag.new(@website)
  end

  def test_register
    check_tdata = lambda do |tdata, callable,  config_base, mandatory_options, initialized|
      assert_equal(callable, tdata.object)
      assert_equal(config_base, tdata.config_base)
      assert_equal(mandatory_options, tdata.mandatory_options)
      assert_equal(initialized, tdata.initialized)
    end

    @tag.register('Webgen::Tag::MyTag')
    check_tdata.call(@tag.instance_eval { @extensions[:my_tag] },
                     'Webgen::Tag::MyTag', 'tag.my_tag', [], false)
    assert(@tag.registered?('my_tag'))

    @tag.register('MyTag', :names => ['mytag', 'other'])
    check_tdata.call(@tag.instance_eval { @extensions[:my_tag] },
                     'Webgen::Tag::MyTag', 'tag.my_tag', [], false)
    assert(@tag.registered?('my_tag'))
    assert(@tag.registered?('other'))

    @tag.register('doit') do |tag, body, context|
      'doit: now'
    end
    assert(@tag.registered?('doit'))

    @tag.register('MyTag', :names => ['other'], :config_base => 'other', :mandatory => ['mandatory'])
    check_tdata.call(@tag.instance_eval { @extensions[:other] },
                     'Webgen::Tag::MyTag', 'other', ['mandatory'], false)
  end

  def test_call
    logger_output = StringIO.new('')
    logger = ::Logger.new(logger_output)
    logger.level = Logger::WARN

    @config.define_option('tag.my_tag.opt', 'param1', 'desc') {|v| raise "Error" unless v.kind_of?(String); v}
    @config.freeze
    @website.expect(:logger, logger)
    @website.expect(:ext, OpenStruct.new)

    context = Webgen::Context.new(@website)

    assert_raises(Webgen::RenderError) { @tag.call('unknown', {}, 'body', context) }

    @tag.register('MyTag', :mandatory => ['mandatory'])
    assert_raises(Webgen::RenderError) { @tag.call('my_tag', {}, 'body', context) }

    @tag.register('MyTag')
    assert_raises(Webgen::RenderError) { @tag.call('my_tag', 5, 'body', context) }
    assert_raises(Webgen::Configuration::Error) { @tag.call('my_tag', {'opt' => :value}, 'body', context) }


    @tag.register('MyTag')
    result = @tag.call('my_tag', nil, 'body', context)
    assert_equal('my_tagbodyparam1', result)
    assert_equal('', logger_output.string)

    result = @tag.call('my_tag', {'opt' => 'value'}, 'body', context)
    assert_equal('my_tagbodyvalue', result)
    assert_equal('', logger_output.string)
    assert_equal('value', context[:config]['tag.my_tag.opt'])

    result = @tag.call('my_tag', {'tag.my_tag.opt' => 'value1', 'unknown' => 'unknown'}, 'body', context)
    assert_equal('my_tagbodyvalue1', result)
    assert_match(/Invalid configuration option 'unknown'/, logger_output.string)

    logger_output.string = ''
    result = @tag.call('my_tag', 'unknown', 'body', context)
    assert_equal('my_tagbodyparam1', result)
    assert_match(/No default mandatory option/, logger_output.string)


    logger_output.string = ''
    @tag.register('MyTag', :mandatory => ['opt'])
    assert_raises(Webgen::RenderError) { @tag.call('my_tag', {}, 'body', context) }

    result = @tag.call('my_tag', 'unknown', 'body', context)
    assert_equal('my_tagbodyunknown', result)
  end

  def test_replace_tags
    @config.define_option('tag.prefix', '', 'desc')
    @config.freeze

    assert_raises(NoMethodError) { @tag.replace_tags("{test:}") }
    @blackboard.dispatch_msg(:website_initialized)

    @tag.replace_tags("{test: {param: value}}") do |tag, params, body|
      assert_equal('test', tag)
      assert_equal({'param' => 'value'}, params)
      assert_equal('', body)
    end
  end

  class StubContext

    def [](key)
      {:config => {'tag.tag.template' => '/tag.template'}}[key]
    end

    def ref_node
      template_node = MiniTest::Mock.new
      template_node.expect(:template_chain, [:hallo])
      node = MiniTest::Mock.new
      node.expect(:resolve!)
    end

  end

  def test_class_render_tag_template
    dest_node = MiniTest::Mock.new
    dest_node.expect(:lang, 'en')
    template_node = MiniTest::Mock.new
    template_node.expect(:template_chain, [:hallo])
    ref_node = MiniTest::Mock.new
    ref_node.expect(:resolve!, template_node, ['/tag.template', 'en', dest_node])
    context = MiniTest::Mock.new
    context.expect(:[], {'tag.tag.template' => '/tag.template'}, [:config])
    context.expect(:ref_node, ref_node)
    context.expect(:content_node, ref_node)
    context.expect(:dest_node, dest_node)
    context.expect(:render_block, 'ahoi', [{:name => "tag.tag", :node => 'first',
                                             :chain => [:hallo, template_node, context.content_node]}])

    Webgen::Tag.render_tag_template(context, 'tag')

    context.verify
    dest_node.verify
    ref_node.verify
    template_node.verify
  end

end
