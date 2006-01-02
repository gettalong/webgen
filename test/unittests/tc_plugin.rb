require 'test/unit'
require 'webgen/plugin'

class Module

  public :remove_const

end


FIXTURE_PATH = File.join( File.dirname(__FILE__), '../fixtures/tc_plugin' ) + '/'

def undo_all
  Testing.constants.each {|c| Testing.remove_const(c)} if Object.const_defined?( :Testing )
  $".delete( File.join( FIXTURE_PATH, 'plugin1.rb' ) )
  $".delete( File.join( FIXTURE_PATH, 'plugin2.rb' ) )
end



class PluginLoaderTest < Test::Unit::TestCase

  def setup
    @l = Webgen::PluginLoader.new
  end

  def teardown
    self.class.remove_const( :TestPlugin ) if self.class.const_defined?( :TestPlugin )
    @l = nil
    undo_all
  end

  def test_load_from_dir
    assert_nothing_thrown do
      @l.load_from_dir( FIXTURE_PATH, '' )
    end
    check_loaded_plugin( @l, Testing::BasicPlugin )
    check_loaded_plugin( @l, Testing::PluginWithData )
    check_loaded_plugin( @l, Testing::DerivedPlugin )
  end

  def test_load_from_file
    assert_nothing_thrown do
      @l.load_from_file( File.join( FIXTURE_PATH, 'plugin1') )
    end
    check_loaded_plugin( @l, Testing::BasicPlugin )
    check_loaded_plugin( @l, Testing::PluginWithData )
  end

  def test_load_from_block
    assert_throws( :plugin_class_found ) do
      Class.new( Webgen::Plugin )
    end
    assert_nothing_thrown do
      @l.load_from_block { self.class.module_eval "class TestPlugin < Webgen::Plugin; end" }
    end
    assert_raise( RuntimeError ) do
      self.class.module_eval "class TestPlugin1 < Webgen::Plugin; end"
    end
    check_loaded_plugin( @l, TestPlugin )
  end

  def test_accessors
    assert_equal( 0, @l.plugins.length )
    @l.load_from_block { self.class.module_eval "class TestPlugin < Webgen::Plugin; end" }
    assert_equal( 1, @l.plugins.length )
    assert_equal( [TestPlugin], @l.plugins )
    assert_equal( TestPlugin, @l.plugin_for_name( 'PluginLoaderTest::TestPlugin' ) )
    assert( @l.has_plugin?( 'PluginLoaderTest::TestPlugin' ) )
  end

  def check_loaded_plugin( loader, plugin )
    assert( loader.plugins.include?( plugin ), "#{plugin} not loaded" )
  end

end


class PluginTest < Test::Unit::TestCase

  def setup
    @l = Webgen::PluginLoader.new
    @l.load_from_dir( FIXTURE_PATH, '' )
  end

  def teardown
    undo_all
    @l = nil
  end

  def test_plugin_config
    check_plugin_data( Testing::BasicPlugin, {}, [], [] )
    check_plugin_data( Testing::PluginWithData, Testing::INFOS_HASH, Testing::PARAM_ARRAY, Testing::DEPS_ARRAY_CHECK )
  end

  def test_ancestor_classes
    assert_equal( [Testing::BasicPlugin], Testing::BasicPlugin.ancestor_classes )
    assert_equal( [Testing::PluginWithData], Testing::PluginWithData.ancestor_classes )
    assert_equal( [Testing::DerivedPlugin, Testing::PluginWithData], Testing::DerivedPlugin.ancestor_classes )
  end

  def check_plugin_data( plugin, infos, params, deps )
    assert_kind_of( OpenStruct, plugin.config )
    assert_equal( plugin, plugin.config.plugin_klass )
    assert_equal( infos, plugin.config.infos )
    if params.length > 0
      assert_equal( params[0], plugin.config.params[params[0]].name )
      assert_equal( params[1], plugin.config.params[params[0]].default )
      assert_equal( params[2], plugin.config.params[params[0]].description )
    end
    assert_equal( deps, plugin.config.dependencies )
    plugin.config.dependencies.each {|dep| assert_kind_of( String, dep)}
  end

end


class PluginManagerTest < Test::Unit::TestCase

  def setup
  end

  def teardown
    undo_all
  end

  def test_add_plugin_classes
    loader = Webgen::PluginLoader.new
    loader.load_from_file( File.join( FIXTURE_PATH, 'plugin1.rb' ) )
    manager = Webgen::PluginManager.new( [loader] )

    assert_raise( Webgen::PluginNotFound ) { manager.add_plugin_classes( loader.plugins) }
    assert_equal( [], manager.plugin_classes )

    loader.load_from_file( File.join( FIXTURE_PATH, 'plugin2.rb' ) )
    assert_nothing_raised { manager.add_plugin_classes( loader.plugins) }
    assert_equal( loader.plugins, manager.plugin_classes )
  end

  def test_init
    loader = Webgen::PluginLoader.new
    loader.load_from_dir( FIXTURE_PATH, '' )

    manager = Webgen::PluginManager.new( [loader] )
    manager.add_plugin_classes( loader.plugins )
    manager.init
    assert_kind_of( Testing::BasicPlugin, manager[Testing::BasicPlugin] )
    assert_kind_of( Testing::PluginWithData, manager['Testing::PluginWithData'] )
  end

  def test_get_param
    loader = Webgen::PluginLoader.new
    loader.load_from_dir( FIXTURE_PATH, '' )
    manager = Webgen::PluginManager.new( [loader] )

    manager.add_plugin_classes( loader.plugins )
    manager.init

    assert_equal( Testing::PARAM_ARRAY[1], manager[Testing::PluginWithData].get_param( Testing::PARAM_ARRAY[0] ) )
    assert_equal( Testing::PARAM_ARRAY[1], manager[Testing::DerivedPlugin].get_param( Testing::PARAM_ARRAY[0] ) )
    assert_equal( manager[Testing::PluginWithData].get_param( Testing::PARAM_ARRAY[0] ),
                  manager.get_param( Testing::PluginWithData, Testing::PARAM_ARRAY[0] ) )
    assert_equal( manager[Testing::PluginWithData].get_param( Testing::PARAM_ARRAY[0] ),
                  manager.get_param( 'Testing::PluginWithData', Testing::PARAM_ARRAY[0] ) )

    #TODO assign plugin configuration to manager, test get changed value
  end

  def test_reset_config
    #TODO
  end

end
