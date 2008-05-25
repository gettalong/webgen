require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor/tags'

class TestContentProcessorTags < Test::Unit::TestCase

  include Test::WebsiteHelper

  class TestTag

    def set_params(*args); end

    def create_tag_params(*args); end

    def call(tag, body, context)
      case tag
      when 'body'
        body
      when 'bodyproc'
        [body, true]
      else
        tag
      end
    end

  end

  def setup
    super
    @obj = Webgen::ContentProcessor::Tags.new
  end

  def test_call
    context = Webgen::ContentProcessor::Context.new(:chain => [Webgen::Tree.new.dummy_root])
    context.content = "{test: }"
    assert_equal('', @obj.call(context).content)

    add_test_tag
    assert_equal('test', @obj.call(context.clone(:content => "{test: }")).content)
    assert_equal('thebody', @obj.call(context.clone(:content => "{body::}thebody{body}")).content)
    assert_equal('test {other:}other test',
                  @obj.call(context.clone(:content => "test{bodyproc::} \\{other:}{other:} {bodyproc}test")).content)
  end

  def test_replace_tags
    check_returned_tags('sdfsdf{asd', [])
    check_returned_tags('sdfsdf}asd', [])
    check_returned_tags('sdfsdf{asd}', [])
    check_returned_tags('sdfsdf{asd: {}as', [])
    check_returned_tags('sdfsdf{test: {test1: }}', [['test', ' {test1: }', '']], 'sdfsdftest1')
    check_returned_tags('sdfsdf{test: {test1: {}}', [['test', '', '']], 'sdfsdf{test: {test1: {}}')
    check_returned_tags('sdfsdf{test:}{test1: }', [['test', '', ''], ['test1', ' ', '']], 'sdfsdftest1test2')
    check_returned_tags('sdfsdf{test:}\\{test1: }', [['test', '', '']], "sdfsdftest1{test1: }")
    check_returned_tags('sdfsdf\\{test:}{test1:}', [['test1', '', '']], "sdfsdf{test:}test1")
    check_returned_tags('sdfsdf{test: asdf}', [['test', ' asdf', '']], "sdfsdftest1")
    check_returned_tags('sdfsdf\\{test: asdf}', [], "sdfsdf{test: asdf}")
    check_returned_tags('sdfsdf\\\\{test: asdf}', [['test', ' asdf', '']], "sdfsdf\\test1")
    check_returned_tags('sdfsdf\\\\\\{test: asdf}sdf', [['test', ' asdf', '']], "sdfsdf\\{test: asdf}sdf")

    check_returned_tags('before{test::}body{test}', [['test', '', 'body']], "beforetest1")
    check_returned_tags('before{test::}body{testno}', [], "before{test::}body{testno}")
    check_returned_tags('before{test::}body\\{test}other{test}', [['test', '', 'body{test}other']], "beforetest1")
    check_returned_tags('before{test::}body\\{test}{test}', [['test', '', 'body{test}']], "beforetest1")
    check_returned_tags('before{test::}body\\{test}\\\\{test}after', [['test', '', 'body{test}\\']], "beforetest1after")
    check_returned_tags('before\\{test::}body{test}', [['test', '', 'body']], "before{test::}body{test}")
    check_returned_tags('before\\\\{test:: asdf}body{test}after', [['test', ' asdf', 'body']], "before\\test1after")
  end

  def test_processor_for_tag
    assert_nil(@obj.instance_eval { processor_for_tag('test') })
    assert_nil(@obj.instance_eval { processor_for_tag(:default) })
    add_test_tag
    assert_not_nil(@obj.instance_eval { processor_for_tag(:default) })
  end

  private

  def add_test_tag
    @website.config['contentprocessor.tags.map'].update(:default => 'TestContentProcessorTags::TestTag')
  end

  def check_returned_tags(content, data, result = content)
    i = 0
    check_proc = proc do |tag, params, body|
      assert_equal(data[i][0], tag, 'tag: ' + content)
      assert_equal(data[i][1], params, 'params: ' + content)
      assert_equal(data[i][2], body, 'body: ' + content)
      i += 1
      'test' + i.to_s
    end
    assert_equal(result, @obj.instance_eval { replace_tags(content, Webgen::Tree.new.dummy_root, &check_proc) })
    assert(i, data.length)
  end

end
