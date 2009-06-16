# -*- encoding: utf-8 -*-

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

    output.string = ''
    assert_equal([{}, true], @obj.create_tag_params("--\nhal:param1\ntest:[;", Webgen::Tree.new.dummy_root))
    output.rewind; assert_match(/Could not parse the tag params/, output.read)

    output.string = ''
    set_params(5)
    assert_equal('param1', @obj.param('testtagbase.testtag.param1'))
    output.rewind; assert_match(/Not all mandatory parameters/, output.read)
    output.rewind; assert_match(/Invalid parameter type/, output.read)

    output.string = ''
    set_params(nil)
    assert_equal('param1', @obj.param('testtagbase.testtag.param1'))
    output.rewind; assert_match(/Not all mandatory parameters/, output.read)

    output.string = ''
    set_params({})
    assert_equal('param1', @obj.param('testtagbase.testtag.param1'))
    output.rewind; assert_match(/Not all mandatory parameters/, output.read)

    output.string = ''
    set_params('test_value')
    assert_equal('test_value', @obj.param('testtagbase.testtag.param3'))
    output.rewind; assert_match(/Not all mandatory parameters/, output.read)

    output.string = ''
    set_params({'param2' => 'test2', 'testtagbase.testtag.param3' => 'test3', 'invalid' => 5})
    assert_equal('test2', @obj.param('testtagbase.testtag.param2'))
    assert_equal('test3', @obj.param('testtagbase.testtag.param3'))
    output.rewind; assert_no_match(/Not all mandatory parameters/, output.read)
    output.rewind; assert_match(/Invalid parameter 'invalid'/, output.read)

    @website.config.data.delete('testtagbase.testtag.param3')
    @website.config.meta_info.delete('testtagbase.testtag.param3')
    output.string = ''
    set_params('default_value')
    output.rewind; assert_match(/No default mandatory parameter specified for tag/, output.read)
  end

  def test_call
    assert_raise(NotImplementedError) { @obj.call(nil, nil, nil) }
  end

  def set_params(params)
    @obj.set_params(@obj.send(:create_params_hash, params, Webgen::Tree.new.dummy_root).first)
  end

end
