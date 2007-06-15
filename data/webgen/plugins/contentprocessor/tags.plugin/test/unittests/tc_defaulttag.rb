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

  def test_set_tag_config
    output = StringIO.new( '' )
    @manager.logger = Webgen::Logger.new( output )
    @manager.logger.level = Logger::WARN

    @manager['Tag/TestTag'].set_tag_config( 5, Webgen::Dummy.new )
    assert_equal( 'param1', @manager['Tag/TestTag'].param( 'param1' ) )
    output.rewind; assert_match( /Not all mandatory parameters/, output.read )
    output.rewind; assert_match( /Invalid parameter type/, output.read )

    output.string = ''
    @manager['Tag/TestTag'].set_tag_config( nil, Webgen::Dummy.new )
    assert_equal( 'param1', @manager['Tag/TestTag'].param( 'param1' ) )
    output.rewind; assert_match( /Not all mandatory parameters/, output.read )

    output.string = ''
    @manager['Tag/TestTag'].set_tag_config( {}, Webgen::Dummy.new )
    assert_equal( 'param1', @manager['Tag/TestTag'].param( 'param1' ) )
    output.rewind; assert_match( /Not all mandatory parameters/, output.read )

    output.string = ''
    @manager['Tag/TestTag'].set_tag_config( 'test_value', Webgen::Dummy.new )
    assert_equal( 'test_value', @manager['Tag/TestTag'].param( 'param3' ) )
    output.rewind; assert_match( /Not all mandatory parameters/, output.read )

    output.string = ''
    @manager['Tag/TestTag'].set_tag_config( {'param2' => 'test2', 'param3' => 'test3', 'invalid' => 5}, Webgen::Dummy.new )
    assert_equal( 'test2', @manager['Tag/TestTag'].param( 'param2' ) )
    assert_equal( 'test3', @manager['Tag/TestTag'].param( 'param3' ) )
    output.rewind; assert_no_match( /Not all mandatory parameters/, output.read )
    output.rewind; assert_match( /Invalid parameter 'invalid'/, output.read )
  end

  def test_process_tag
    assert_raises( NotImplementedError ) { @manager['Tag/DefaultTag'].process_tag( nil, nil, nil, nil ) }
  end

end
