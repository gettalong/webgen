require 'webgen/test'
require 'webgen/node'

class TagsTest < Webgen::PluginTestCase

  plugin_to_test 'ContentProcessor/Tags'

  def test_process
    content = "{test: }"
    assert_equal( '', @plugin.process( content, {:chain => [Webgen::Dummy.new]}, {} ) )

    @manager.load_plugin_bundle( fixture_path('test.plugin') )
    assert_equal( 'test', @plugin.process( "{test:}", {:chain => [Webgen::Dummy.new]}, {} ) )
    assert_equal( 'thebody', @plugin.process( "{body::}thebody{body}", {:chain => [Webgen::Dummy.new]}, {} ) )
    assert_equal( 'test {other:}other test', @plugin.process( "test{bodyproc::} \\{other:}{other:} {bodyproc}test",
                                                              {:chain => [Webgen::Dummy.new]}, {} ) )
  end

  def test_replace_tags
    check_returned_tags( 'sdfsdf{asd', [] )
    check_returned_tags( 'sdfsdf}asd', [] )
    check_returned_tags( 'sdfsdf{asd}', [] )
    check_returned_tags( 'sdfsdf{asd: {}as', [] )
    check_returned_tags( 'sdfsdf{test: {test1: }}', [['test', ' {test1: }', '']], 'sdfsdftest1' )
    check_returned_tags( 'sdfsdf{test: {test1: {}}', [['test', '', '']], 'sdfsdf{test: {test1: {}}' )
    check_returned_tags( 'sdfsdf{test:}{test1: }', [['test', '', ''], ['test1', ' ', '']], 'sdfsdftest1test2' )
    check_returned_tags( 'sdfsdf{test:}\\{test1: }', [['test', '', '']], "sdfsdftest1{test1: }" )
    check_returned_tags( 'sdfsdf\\{test:}{test1:}', [['test1', '', '']], "sdfsdf{test:}test1" )
    check_returned_tags( 'sdfsdf{test: asdf}', [['test', ' asdf', '']], "sdfsdftest1" )
    check_returned_tags( 'sdfsdf\\{test: asdf}', [], "sdfsdf{test: asdf}" )
    check_returned_tags( 'sdfsdf\\\\{test: asdf}', [['test', ' asdf', '']], "sdfsdf\\test1" )
    check_returned_tags( 'sdfsdf\\\\\\{test: asdf}sdf', [['test', ' asdf', '']], "sdfsdf\\{test: asdf}sdf" )

    check_returned_tags( 'before{test::}body{test}', [['test', '', 'body']], "beforetest1" )
    check_returned_tags( 'before{test::}body{testno}', [], "before{test::}body{testno}" )
    check_returned_tags( 'before{test::}body\\{test}other{test}', [['test', '', 'body{test}other']], "beforetest1" )
    check_returned_tags( 'before{test::}body\\{test}{test}', [['test', '', 'body{test}']], "beforetest1" )
    check_returned_tags( 'before{test::}body\\{test}\\\\{test}after', [['test', '', 'body{test}\\']], "beforetest1after" )
    check_returned_tags( 'before\\{test::}body{test}', [['test', '', 'body']], "before{test::}body{test}" )
    check_returned_tags( 'before\\\\{test:: asdf}body{test}after', [['test', ' asdf', 'body']], "before\\test1after" )
  end

  def test_processor_for_tag
    assert_nil( @plugin.instance_eval { processor_for_tag( 'test' ) } )
    assert_nil( @plugin.instance_eval { processor_for_tag( :default ) } )
    @manager.load_plugin_bundle( fixture_path('test.plugin') )
    assert_not_nil( @plugin.instance_eval { processor_for_tag( :default ) } )
  end

  def test_registered_tags
    assert_equal( {}, @plugin.instance_eval { registered_tags } )
    @manager.load_plugin_bundle( fixture_path('test.plugin') )
    assert_equal( {:default=>@manager['Tag/TestTag']}, @plugin.instance_eval { registered_tags } )
  end

  #######
  private
  #######

  def check_returned_tags( content, data, result = content )
    i = 0
    check_proc = proc do |tag, params, body|
      assert_equal( data[i][0], tag, 'tag: ' + content )
      assert_equal( data[i][1], params, 'params: ' + content )
      assert_equal( data[i][2], body, 'body: ' + content )
      i += 1
      'test' + i.to_s
    end
    assert_equal( result, @plugin.instance_eval { replace_tags( content, Webgen::Dummy.new, &check_proc ) } )
    assert( i, data.length )
  end

end
