# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/utils/tag_parser'

class TestTagParser < Minitest::Test

  include Webgen::TestHelper

  def test_replace_tags
    @parser = Webgen::Utils::TagParser.new

    # no webgen tag in content
    check_returned_tags('sdfsdf{asd', [])
    check_returned_tags('sdfsdf}asd', [])
    check_returned_tags('sdfsdf{asd}', [])

    # error with invalid brace nesting
    check_returned_tags('sdfsdf{asd: {}as', [], true)
    check_returned_tags('sdfsdf{test: {test1: {}}', [], true)

    # error with invalid params
    check_returned_tags('sdfsdf{test: {test1: [}}', [], true)

    # normal behavious
    check_returned_tags('sdfsdf{test: {test1: }}', [['test', {'test1' => nil}, '']], 'sdfsdftest1')
    check_returned_tags('sdfsdf{test:}{test1: }', [['test', nil, ''], ['test1', nil, '']], 'sdfsdftest1test2')

    # brace escaping
    check_returned_tags('sdfsdf{test:}\\{test1: }', [['test', nil, '']], "sdfsdftest1{test1: }")
    check_returned_tags('sdfsdf\\{test:}{test1:}', [['test1', nil, '']], "sdfsdf{test:}test1")
    check_returned_tags('sdfsdf{test: asdf}', [['test', 'asdf', '']], "sdfsdftest1")
    check_returned_tags('sdfsdf\\{test: asdf}', [], "sdfsdf{test: asdf}")
    check_returned_tags('sdfsdf\\\\{test: asdf}', [['test', 'asdf', '']], "sdfsdf\\test1")
    check_returned_tags('sdfsdf\\\\\\{test: asdf}sdf', [['test', 'asdf', '']], "sdfsdf\\{test: asdf}sdf")

    # error when no end tag is found
    check_returned_tags('before{test::}body{testno}', [], true)

    # tags with body
    check_returned_tags('before{test::}body{test}', [['test', nil, 'body']], "beforetest1")
    check_returned_tags('before{test::}body\\{test}other{test}', [['test', nil, 'body{test}other']], "beforetest1")
    check_returned_tags('before{test::}body\\{test}{test}', [['test', nil, 'body{test}']], "beforetest1")
    check_returned_tags('before{test::}body\\{test}\\\\{test}after', [['test', nil, 'body{test}\\']], "beforetest1after")
    check_returned_tags('before\\{test::}body{test}', [['test', nil, 'body']], "before{test::}body{test}")
    check_returned_tags('before\\\\{test:: asdf}body{test}after', [['test', 'asdf', 'body']], "before\\test1after")

    # content with non-ascii characters
    check_returned_tags('sdfsüdf{test: }', [['test', nil, '']], "sdfsüdftest1")
    check_returned_tags('sdfsüüdf{test: asdf}', [['test', 'asdf', '']], "sdfsüüdftest1")
    check_returned_tags('sdfsüüdf{test: asüdf}a', [['test', 'asüdf', '']], "sdfsüüdftest1a")
    check_returned_tags('sdfsüüdf\\{test: asdf}ab', [], "sdfsüüdf{test: asdf}ab")
    check_returned_tags('sdfsüüdf\\\\{test: asdf}ab', [['test', 'asdf', '']], "sdfsüüdf\\test1ab")
    check_returned_tags('sdfsüüdf\\\\\\{test: asdf}ab', [], "sdfsüüdf\\{test: asdf}ab")
    check_returned_tags('sdfsüüdf{test:: asdf}abü{test}ab', [['test', 'asdf', 'abü']], "sdfsüüdftest1ab")
  end

  def test_replace_tags_with_prefix
    @parser = Webgen::Utils::TagParser.new('hallo')
    check_returned_tags('sdfsüdf{test: }', [], "sdfsüdf{test: }")
    check_returned_tags('sdfsüdf{hallotest: }', [['test', nil, '']], "sdfsüdftest1")
  end

  def check_returned_tags(content, data, result = content)
    i = 0
    check_proc = proc do |tag, params, body|
      assert_equal(data[i][0], tag, 'error on tag with content: ' + content)
      assert(data[i][1] == params, 'error on params with content: ' + content)
      assert_equal(data[i][2], body, 'error on body with content: ' + content)
      i += 1
      'test' + i.to_s
    end

    if result.kind_of?(TrueClass)
      assert_error_on_line(Webgen::Utils::TagParser::Error, 1) { @parser.replace_tags(content, &check_proc) }
    else
      @parser.replace_tags(content, &check_proc)
      assert_equal(content, result)
    end
    assert(i, data.length)
  end

  def test_error_line_and_column
    @parser = Webgen::Utils::TagParser.new
    check_line_and_column("error\non\nline 3 {test1: {}", 3, 8)
    check_line_and_column("line {test1: {}", 1, 6)
    check_line_and_column("error\no\n{test1: {}", 3, 1)
  end

  def check_line_and_column(content, line, column)
    begin
      @parser.replace_tags(content) { }
    rescue Webgen::Utils::TagParser::Error => e
      assert_equal(line, e.line)
      assert_equal(column, e.column)
    end
  end

end
