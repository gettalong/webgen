require 'webgen/test'

class DefaultTagTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/DefaultTag'

  def setup
    super
    @manager.load_plugin_bundle( fixture_path('test.plugin') )
  end

  def test_tags
    assert_equal( [:default, 'test'], @manager['Tag/TestTag'].tags )
  end

  def set_params( params )
    @manager['Tag/TestTag'].set_params( @manager['Tag/TestTag'].instance_eval { create_params_hash( params, Webgen::Dummy.new ) } )
  end

  def test_tag_params
    output = StringIO.new( '' )
    @manager.logger = Webgen::Logger.new( output )
    @manager.logger.level = Logger::WARN

    output.string = ''
    assert_equal( {}, @manager['Tag/TestTag'].tag_params( "--\nhal:param1\ntest:[;", Webgen::Dummy.new ) )
    output.rewind; assert_match( /Could not parse the tag params/, output.read )

    output.string = ''
    set_params( 5 )
    assert_equal( 'param1', @manager['Tag/TestTag'].param( 'param1' ) )
    output.rewind; assert_match( /Not all mandatory parameters/, output.read )
    output.rewind; assert_match( /Invalid parameter type/, output.read )

    output.string = ''
    set_params( nil )
    assert_equal( 'param1', @manager['Tag/TestTag'].param( 'param1' ) )
    output.rewind; assert_match( /Not all mandatory parameters/, output.read )

    output.string = ''
    set_params( {} )
    assert_equal( 'param1', @manager['Tag/TestTag'].param( 'param1' ) )
    output.rewind; assert_match( /Not all mandatory parameters/, output.read )

    output.string = ''
    set_params( 'test_value' )
    assert_equal( 'test_value', @manager['Tag/TestTag'].param( 'param3' ) )
    output.rewind; assert_match( /Not all mandatory parameters/, output.read )

    output.string = ''
    set_params( {'param2' => 'test2', 'param3' => 'test3', 'invalid' => 5} )
    assert_equal( 'test2', @manager['Tag/TestTag'].param( 'param2' ) )
    assert_equal( 'test3', @manager['Tag/TestTag'].param( 'param3' ) )
    output.rewind; assert_no_match( /Not all mandatory parameters/, output.read )
    output.rewind; assert_match( /Invalid parameter 'invalid'/, output.read )
  end

  def test_process_tag
    assert_raises( NotImplementedError ) { @manager['Tag/DefaultTag'].process_tag( nil, nil, nil ) }
  end

end
