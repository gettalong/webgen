# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'stringio'
require 'webgen/tag'

class TestTagBase < Test::Unit::TestCase

  include Test::WebsiteHelper

  class TestTag; include Webgen::Tag::Base; end

  def setup
    super
    @website.config.testtagbase.testtag.param1 'param1'
    @website.config.testtagbase.testtag.param2 nil, :mandatory=> true
    @website.config.testtagbase.testtag.param3 'param3', :mandatory => 'default'
    @obj = TestTag.new
  end

  def test_tag_config_base
    assert_equal('testtagbase.testtag', @obj.send(:tag_config_base))
  end

  def test_tag_params_list
    params = [1,2,3].collect {|i| 'testtagbase.testtag.param' + i.to_s}
    assert_equal(params.sort, @obj.send(:tag_params_list).sort)
  end

  def test_create_tag_params
    output = StringIO.new('')
    @website.logger = ::Logger.new(output)
    @website.logger.level = Logger::WARN

    assert_raise(Webgen::RenderError) { @obj.create_tag_params("--\nhal:param1\ntest:[;", Webgen::Tree.new.dummy_root) }

    assert_raise(Webgen::RenderError) { set_params(5) }
    assert_raise(Webgen::RenderError) { set_params(nil) }
    assert_raise(Webgen::RenderError) { set_params({}) }
    assert_raise(Webgen::RenderError) { set_params('test_value') }

    output.string = ''
    set_params({'param2' => 'test2', 'testtagbase.testtag.param3' => 'test3', 'invalid' => 5})
    assert_equal('test2', @obj.param('testtagbase.testtag.param2'))
    assert_equal('test3', @obj.param('testtagbase.testtag.param3'))
    output.rewind; assert_match(/Invalid parameter 'invalid'/, output.read)

    @website.config.data.delete('testtagbase.testtag.param3')
    @website.config.meta_info.delete('testtagbase.testtag.param3')
    assert_raise(Webgen::RenderError) { set_params('default_value') }
  end

  def test_call
    assert_raise(NotImplementedError) { @obj.call(nil, nil, nil) }
  end

  def set_params(params)
    @obj.set_params(@obj.send(:create_params_hash, params, Webgen::Tree.new.dummy_root))
  end

end
