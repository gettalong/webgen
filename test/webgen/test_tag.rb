# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/tag'
require 'webgen/configuration'
require 'webgen/context'
require 'stringio'
require 'logger'

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
    assert(@tag.registered?('mytag'))

    @tag.register('MyTag', :names => ['mytag', 'other'])
    assert(@tag.registered?('mytag'))
    assert(@tag.registered?('other'))

    @tag.register('doit') do |tag, body, context|
      'doit: now'
    end
    assert(@tag.registered?('doit'))
  end

  def test_registered
    refute(@tag.registered?('mytag'))
    @tag.register('MyTag')
    assert(@tag.registered?('mytag'))
  end

  def test_tag_data
    @tag.register('Webgen::Tag::MyTag')
    assert_equal(['Webgen::Tag::MyTag', 'tag.mytag', [], false], @tag.instance_eval { @tags['mytag'] })

    @tag.register('MyTag')
    assert_equal(['Webgen::Tag::MyTag', 'tag.mytag', [], false], @tag.instance_eval { @tags['mytag'] })

    @tag.register('MyTag', :names => ['other'], :config_base => 'other', :mandatory => ['mandatory'])
    assert_equal(['Webgen::Tag::MyTag', 'other', ['mandatory'], false], @tag.instance_eval { @tags['other'] })
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

    context = Webgen::Context.new(website)


    assert_raises(Webgen::RenderError) { @tag.call('unknown', {}, 'body', context) }

    @tag.register('MyTag')
    assert_raises(Webgen::RenderError) { @tag.call('mytag', 5, 'body', context) }
    assert_raises(Webgen::Configuration::Error) { @tag.call('mytag', {'opt' => :value}, 'body', context) }


    @tag.register('MyTag')
    result = @tag.call('mytag', nil, 'body', context)
    assert_equal('mytagbodyparam1', result)
    assert_equal('', logger_output.string)

    result = @tag.call('mytag', {'opt' => 'value'}, 'body', context)
    assert_equal('mytagbodyvalue', result)
    assert_equal('', logger_output.string)
    assert_equal('value', context[:config]['tag.mytag.opt'])

    result = @tag.call('mytag', {'tag.mytag.opt' => 'value', 'unknown' => 'unknown'}, 'body', context)
    assert_equal('mytagbodyvalue', result)
    assert_match(/Invalid configuration option 'unknown'/, logger_output.string)

    logger_output.string = ''
    result = @tag.call('mytag', 'unknown', 'body', context)
    assert_equal('mytagbodyparam1', result)
    assert_match(/No default mandatory option/, logger_output.string)


    logger_output.string = ''
    @tag.register('MyTag', :mandatory => ['opt'])
    assert_raises(Webgen::RenderError) { @tag.call('mytag', {}, 'body', context) }

    result = @tag.call('mytag', 'unknown', 'body', context)
    assert_equal('mytagbodyunknown', result)
  end

  def test_static_tag
    static = Webgen::Tag.static
    assert_kind_of(Webgen::Tag, static)
    assert(static.registered?('date'))
  end

  def test_clone
    static = Webgen::Tag.static.clone
    cloned = static.clone
    cloned.register('MyTag')
    refute(static.registered?('mytag'))
  end

end
