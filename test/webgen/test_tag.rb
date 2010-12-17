# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/tag'
require 'webgen/configuration'
require 'webgen/context'
require 'stringio'
require 'logger'
require 'ostruct'

class Webgen::Tag::MyTag

  def call(tag, body, context)
    "#{tag}#{body}#{context[:config]['tag.mytag.opt']}"
  end

end


class TestTag < MiniTest::Unit::TestCase

  def setup
    @tag = Webgen::Tag.new
  end

  def test_register
    @tag.register('Webgen::Tag::MyTag')
    assert_equal(['Webgen::Tag::MyTag', 'tag.mytag', [], false], @tag.instance_eval { @extensions[:my_tag] })
    assert(@tag.registered?('my_tag'))

    @tag.register('MyTag', :names => ['mytag', 'other'])
    assert_equal(['Webgen::Tag::MyTag', 'tag.mytag', [], false], @tag.instance_eval { @extensions[:my_tag] })
    assert(@tag.registered?('my_tag'))
    assert(@tag.registered?('other'))

    @tag.register('doit') do |tag, body, context|
      'doit: now'
    end
    assert(@tag.registered?('doit'))

    @tag.register('MyTag', :names => ['other'], :config_base => 'other', :mandatory => ['mandatory'])
    assert_equal(['Webgen::Tag::MyTag', 'other', ['mandatory'], false], @tag.instance_eval { @extensions[:other] })
  end

  def test_call
    logger_output = StringIO.new('')
    logger = ::Logger.new(logger_output)
    logger.level = Logger::WARN

    config = Webgen::Configuration.new
    config.define_option('tag.mytag.opt', 'param1', 'desc') {|v| raise "Error" unless v.kind_of?(String); v}

    website = MiniTest::Mock.new
    website.expect(:logger, logger)
    website.expect(:config, config)
    website.expect(:ext, OpenStruct.new)

    context = Webgen::Context.new(website)


    assert_raises(Webgen::RenderError) { @tag.call('unknown', {}, 'body', context) }

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
    assert_equal('value', context[:config]['tag.mytag.opt'])

    result = @tag.call('my_tag', {'tag.mytag.opt' => 'value', 'unknown' => 'unknown'}, 'body', context)
    assert_equal('my_tagbodyvalue', result)
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

end
