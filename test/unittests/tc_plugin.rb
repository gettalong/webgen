require 'webgen/test'
require 'webgen/plugin'


class PluginLoaderTest < Webgen::TestCase

  def setup
    @wrapper = Module.new
    @l = Webgen::PluginLoader.new( @wrapper )
  end

  def teardown
    self.class.remove_const(:TestPlugin) if self.class.const_defined?(:TestPlugin)
  end

  def test_load_from_dir
    assert_nothing_thrown do
      @l.load_from_dir( fixture_path, '' )
    end
    check_loaded_plugin_class( @l, @wrapper::Testing::BasicPlugin )
    check_loaded_plugin_class( @l, @wrapper::Testing::PluginWithData )
    check_loaded_plugin_class( @l, @wrapper::Testing::DerivedPlugin )
  end

  def test_load_from_file
    assert_nothing_thrown do
      @l.load_from_file( fixture_path( 'plugin1') )
    end
    check_loaded_plugin_class( @l, @wrapper::Testing::BasicPlugin )
    check_loaded_plugin_class( @l, @wrapper::Testing::PluginWithData )
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
    check_loaded_plugin_class( @l, TestPlugin )
  end

  def test_accessors
    assert_equal( 0, @l.plugin_classes.length )
    @l.load_from_block { self.class.module_eval "class TestPlugin < Webgen::Plugin; end" }
    assert_equal( 1, @l.plugin_classes.length )
    assert_equal( [TestPlugin], @l.plugin_classes )
    assert_equal( TestPlugin, @l.plugin_class_for_name( 'PluginLoaderTest/TestPlugin' ) )
    assert( @l.has_plugin?( 'PluginLoaderTest/TestPlugin' ) )
  end

  def test_default_plugin_loader
    assert_equal( 0, Webgen::DEFAULT_PLUGIN_LOADER.plugin_classes.length )
  end

  def check_loaded_plugin_class( loader, plugin )
    assert( loader.plugin_classes.include?( plugin ), "#{plugin} not loaded" )
  end

end


class PluginTest < Webgen::TestCase

  def setup
    @wrapper = Module.new
    @l = Webgen::PluginLoader.new( @wrapper )
    @l.load_from_dir( fixture_path, '' )
  end

  def test_plugin_config
    check_plugin_data( @wrapper::Testing::BasicPlugin, 'Testing/BasicPlugin', {}, [], [] )
    check_plugin_data( @wrapper::Testing::PluginWithData, 'Testing/PluginWithData', @wrapper::Testing::INFOS_HASH,
                       @wrapper::Testing::PARAM_ARRAY, @wrapper::Testing::DEPS_ARRAY )
  end

  def test_ancestor_classes
    assert_equal( [@wrapper::Testing::BasicPlugin], @wrapper::Testing::BasicPlugin.ancestor_classes )
    assert_equal( [@wrapper::Testing::PluginWithData], @wrapper::Testing::PluginWithData.ancestor_classes )
    assert_equal( [@wrapper::Testing::DerivedPlugin, @wrapper::Testing::PluginWithData], @wrapper::Testing::DerivedPlugin.ancestor_classes )
  end

  def check_plugin_data( plugin, name, infos, params, deps )
    assert_kind_of( OpenStruct, plugin.config )
    assert_equal( plugin, plugin.config.plugin_klass )
    assert_equal( name, plugin.plugin_name )
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


class HandlerPluginTest < Webgen::TestCase

  def setup
    @wrapper = Module.new
    @l = Webgen::PluginLoader.new( @wrapper )
    @l.load_from_file( fixture_path( 'handlerplugin.rb' ) )
  end

  def test_registered_handler
    assert_equal( 3, @l.plugin_classes.length )
    assert_equal( nil, @wrapper::Testing::BaseHandler.registered_handler )
    assert_equal( 'handler1', @wrapper::Testing::Handler1.registered_handler )
    assert_equal( nil, @wrapper::Testing::Handler2.registered_handler )
  end

  def test_registered_handlers
    manager = Webgen::PluginManager.new( [@l] )
    manager.add_plugin_classes( @l.plugin_classes )
    manager.init

    assert_equal( {'handler1' => manager['Testing/Handler1']}, manager['Testing/BaseHandler'].registered_handlers )
  end

end


class DummyConfig

  def initialize
    @config = {
      'Testing/BasicPlugin' => { 'param' => 'value' },
      'Testing/PluginWithData' => { 'test' => [6,7] },
      'Testing/DerivedPlugin' => { 'test' => [7,8] }
    }
  end

  def param_for_plugin( plugin, param )
    @config[plugin][param] || (raise Webgen::PluginParamNotFound.new( plugin, param ))
  end

end


class PluginManagerTest < Webgen::TestCase

  def test_add_plugin_classes
    loader = Webgen::PluginLoader.new
    loader.load_from_file( fixture_path( 'plugin1.rb' ) )
    manager = Webgen::PluginManager.new( [loader] )

    assert_raise( Webgen::PluginNotFound ) { manager.add_plugin_classes( loader.plugin_classes) }
    assert_equal( [], manager.plugin_classes )

    loader.load_from_file( fixture_path( 'plugin2.rb' ) )
    assert_nothing_raised { manager.add_plugin_classes( loader.plugin_classes) }
    assert_equal( loader.plugin_classes, manager.plugin_classes )
  end

  def test_init
    loader = Webgen::PluginLoader.new( wrapper = Module.new )
    loader.load_from_dir( fixture_path, '' )

    manager = Webgen::PluginManager.new( [loader] )
    manager.add_plugin_classes( loader.plugin_classes )
    manager.init
    assert_equal( 5, manager.plugins.length )

    assert_kind_of( wrapper::Testing::BasicPlugin, manager[wrapper::Testing::BasicPlugin] )
    assert_kind_of( wrapper::Testing::DerivedPlugin, manager['Testing/DerivedPlugin'] )
    assert_nil( manager['Testing/PluginWithData'] )
  end

  def test_param_for_plugin
    loader = Webgen::PluginLoader.new( wrapper = Module.new )
    loader.load_from_dir( fixture_path, '' )
    manager = Webgen::PluginManager.new( [loader] )

    manager.add_plugin_classes( loader.plugin_classes )
    manager.init

    other_loader = Webgen::PluginLoader.new
    other_loader.load_from_block { self.class.module_eval "class FalsePlugin < Webgen::Plugin; end" }

    assert_raise( Webgen::PluginParamNotFound ) { manager.param_for_plugin( FalsePlugin, 'param' ) }

    assert_equal( wrapper::Testing::PARAM_ARRAY[1], manager.param_for_plugin( wrapper::Testing::PluginWithData, wrapper::Testing::PARAM_ARRAY[0] ) )
    assert_equal( wrapper::Testing::PARAM_ARRAY[1], manager[wrapper::Testing::DerivedPlugin].param( wrapper::Testing::PARAM_ARRAY[0] ) )
    assert_equal( manager[wrapper::Testing::DerivedPlugin].param( wrapper::Testing::PARAM_ARRAY[0] ),
                  manager.param_for_plugin( 'Testing/PluginWithData', wrapper::Testing::PARAM_ARRAY[0] ) )

    assert_equal( wrapper::Testing::PARAM_ARRAY[1], manager[wrapper::Testing::BasicPlugin].param( wrapper::Testing::PARAM_ARRAY[0], 'Testing/PluginWithData' ) )

    manager.plugin_config = DummyConfig.new
    assert_raise( Webgen::PluginParamNotFound ) { manager.param_for_plugin( 'Testing/BasicPlugin', 'param' ) }
    assert_equal( [6,7], manager.param_for_plugin( wrapper::Testing::PluginWithData, wrapper::Testing::PARAM_ARRAY[0] ) )
    assert_equal( [6,7], manager[wrapper::Testing::DerivedPlugin].param( wrapper::Testing::PARAM_ARRAY[0] ) )

    assert_equal( 'otherparam', manager.param_for_plugin( 'Testing/PluginWithData', 'otherparam' ) )
  end

end
