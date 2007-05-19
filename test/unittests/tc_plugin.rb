require 'webgen/test'
require 'webgen/plugin'


class PluginManagerTest < Webgen::TestCase

  class TestConfigurator

    def initialize( value, stop )
      @value, @stop = value, stop
    end

    def param( name, plugin, cur_val )
      if [plugin,name] == ['Test2Plugin', 'test']
        [@stop, @value]
      else
        [false, cur_val]
      end
    end

  end

  def setup
    @manager = Webgen::PluginManager.new
  end

  def teardown
    @manager = nil
  end

  def test_accessors
    assert_kind_of( Array, @manager.configurators )
    assert_kind_of( Hash, @manager.plugins )
    assert( @manager.plugins.empty? )
    assert_kind_of( Webgen::SpecialHash, @manager.plugin_infos )
    assert_kind_of( Webgen::SpecialHash, @manager.resources )
  end

  def test_load_all_plugin_bundles
    @manager.load_all_plugin_bundles( fixture_path( 'empty.plugin' ) )
    assert_equal( 0, @manager.plugin_infos.length )
    assert_equal( 0, @manager.resources.length )

    @manager.load_all_plugin_bundles( fixture_path )
    assert( @manager.plugin_infos.include?( 'TestPlugin' ) )
  end

  def test_load_plugin_bundle
    assert_raise( RuntimeError ) { @manager.load_plugin_bundle( fixture_path( 'invalid_plugin_yaml' ) ) }

    @manager.load_plugin_bundle( fixture_path( 'test.plugin' ) )
    assert_raise( RuntimeError ) { @manager.load_plugin_bundle( fixture_path( 'test.plugin' ) ) }
    assert( @manager.plugin_infos.include?( 'TestPlugin' ) )
    assert_equal( 'TestPlugin', @manager.plugin_infos['TestPlugin']['plugin']['name'] )
    assert_equal( File.expand_path( fixture_path( 'test.plugin' ) ), @manager.plugin_infos['TestPlugin']['plugin']['dir'] )
    assert_equal( 'TestPlugin', @manager.plugin_infos['TestPlugin']['plugin']['class'] )
    assert_equal( 'plugin.rb', @manager.plugin_infos['TestPlugin']['plugin']['file'] )
    assert_equal( 'documentation.page', @manager.plugin_infos['TestPlugin']['plugin']['docufile'] )
    assert_equal( {}, @manager.plugin_infos['TestPlugin']['params'] )

    @manager.load_plugin_bundle( fixture_path( 'test2.plugin' ) )
    assert( @manager.plugin_infos.include?( 'Test2Plugin' ) )
    assert_equal( 'Test2Plugin', @manager.plugin_infos['Test2Plugin']['plugin']['name'] )
    assert_equal( File.expand_path( fixture_path( 'test2.plugin' ) ), @manager.plugin_infos['Test2Plugin']['plugin']['dir'] )
    assert_equal( 'MyPlugin', @manager.plugin_infos['Test2Plugin']['plugin']['class'] )
    assert_equal( 'plugin2.rb', @manager.plugin_infos['Test2Plugin']['plugin']['file'] )
    assert_equal( 'mydoc.page', @manager.plugin_infos['Test2Plugin']['plugin']['docufile'] )
    assert_equal( {'test'=>{'default'=>'hello'}}, @manager.plugin_infos['Test2Plugin']['params'] )
    assert( @manager.resources.include?( 'webgen/test2res' ) )
    assert_equal( 'myfile.resource myfile resource test2.plugin', @manager.resources['webgen/test2res']['test'] )
  end

  def test_load_local
    @manager.load_all_plugin_bundles( fixture_path )
    @manager.init_plugins( ['Test2Plugin'] )
    local_file = File.expand_path( fixture_path( 'test2.plugin/local_file.rb' ) )
    assert( @manager.instance_eval { @loaded_features.include?( local_file ) } )
  end

  def test_init_plugins
    @manager.load_all_plugin_bundles( fixture_path )
    @manager.init_plugins( ['Test2Plugin', 'TestPlugin'] )
    assert( @manager.plugins.include?( 'Test2Plugin' ) )
    assert( @manager.plugins.include?( 'TestPlugin' ) )

    @manager.plugins = {}
    @manager.init_plugins( ['Test2Plugin'] )
    assert( @manager.plugins.include?( 'TestPlugin' ) )
    assert( @manager.plugins.include?( 'Test2Plugin' ) )

    @manager.plugins = {}
    assert_raise( RuntimeError ) { @manager.init_plugins( ['InvalidDepPlugin'] ) }
    assert_raise( RuntimeError ) { @manager.init_plugins( ['InvalidFilePlugin'] ) }
  end

  def test_bracket_accessor
    @manager.load_all_plugin_bundles( fixture_path )
    assert_not_nil( @manager['Test2Plugin'] )
    assert( @manager.plugins.include?( 'TestPlugin' ) )
  end

  def test_param
    @manager.load_all_plugin_bundles( fixture_path )
    assert_equal( 'hello',  @manager.param( 'test', 'Test2Plugin' ) )
    assert_equal( 'hello',  @manager['Test2Plugin'].param( 'test' ) )

    assert_raise( RuntimeError ) { assert_equal( 'hello',  @manager['TestPlugin'].param( 'test' ) ) }
    assert_equal( 'hello',  @manager['TestPlugin'].param( 'test', 'Test2Plugin' ) )

    notstopped = TestConfigurator.new( 'notstopped', false)
    stopped = TestConfigurator.new( 'stopped', true )

    @manager.configurators = [notstopped, stopped]
    assert_equal( 'stopped', @manager.param( 'test', 'Test2Plugin' ) )
    @manager.configurators = [stopped, notstopped]
    assert_equal( 'stopped', @manager.param( 'test', 'Test2Plugin' ) )
  end

end


class PluginTest < Webgen::TestCase

  def setup
    @manager = Webgen::PluginManager.new
    @manager.logger = nil
    @manager.load_all_plugin_bundles( fixture_path )
  end

  def teardown
    @manager = nil
  end

  def test_accessors
    assert_equal( 'Test2Plugin', @manager['Test2Plugin'].plugin_name )
  end

  # only used for test_log
  def method_missing( id, *args, &block )
    assert_equal( :error, id )
    assert_equal( 'test', block.call )
  end

  def test_log
    assert_nil( @manager['Test2Plugin'].log(:error) {'test'} )
    @manager.logger = self
    assert_nil( @manager['Test2Plugin'].log(:error) {'test'} )
  end

  def test_param
    assert_equal( 'hello',  @manager['Test2Plugin'].param( 'test' ) )

    assert_raise( RuntimeError ) { assert_equal( 'hello',  @manager['TestPlugin'].param( 'test' ) ) }
    assert_equal( 'hello',  @manager['TestPlugin'].param( 'test', 'Test2Plugin' ) )
  end

end


class SpecialHashTest < Webgen::TestCase

  def setup
    @h = Webgen::SpecialHash.new
    ((@h['item1'] = {})['item11'] = {})['item111'] = 'value'
    (@h['item2'] = {})['item21'] = {}
  end

  def test_get
    assert_equal( 'value', @h.get( 'item1', 'item11', 'item111' ) )
    assert_equal( nil, @h.get( 'item1', 'item11', 'item112' ) )
  end

  def test_bracket_accessor
    assert_equal( [['item1', @h['item1']], ['item2', @h['item2']]], @h[/^item/] )
  end

end

=begin

  def test_load_optional_part
    assert_nothing_thrown do
      @l.load_from_file( fixture_path( 'plugin1') )
    end
    assert_not_nil( @l.optional_parts['test'] )
    assert_equal( ['unknown'], @l.optional_parts['test'][:needed_gems] )
    assert( !@l.optional_parts['test'][:loaded] )
  end

=end
