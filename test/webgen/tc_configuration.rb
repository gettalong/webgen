require 'test/unit'
require 'webgen/configuration'
require 'setup'

class PluginTest < Test::Unit::TestCase

  class TestPlugin < Webgen::Plugin

    plugin "plugin"
    summary "summary"
    description "description"
    depends_on 'depends_on'
    add_param "name", TestPlugin, "description"

    def param( name )
      get_param( name )
    end

    def param?( name )
      has_param?( name )
    end

    def param_set(name, value)
      self[name] = value
    end

  end

  class Test2Plugin < TestPlugin
  end

  def setup
    @x = Webgen::Plugin.config[TestPlugin.name].obj = TestPlugin.new
    @x2 = Test2Plugin.new
  end


  def test_class_inherited
    assert_instance_of( OpenStruct, Webgen::Plugin.config[TestPlugin.name] )
    assert_equal( TestPlugin, Webgen::Plugin.config[TestPlugin.name].klass )
  end

  def test_setter_methods
    ['plugin','summary','description'].each do |text|
      assert_equal( text, Webgen::Plugin.config[TestPlugin.name].send( text ) )
    end
    assert_instance_of( Array, Webgen::Plugin.config[TestPlugin.name].dependencies )
    assert_equal( ['depends_on'], Webgen::Plugin.config[TestPlugin.name].dependencies )
    assert_instance_of( Hash, Webgen::Plugin.config[TestPlugin.name].params )
    assert_equal( 'name', Webgen::Plugin.config[TestPlugin.name].params['name'].name )
    assert_equal( TestPlugin, Webgen::Plugin.config[TestPlugin.name].params['name'].value )
    assert_equal( TestPlugin, Webgen::Plugin.config[TestPlugin.name].params['name'].default )
    assert_equal( 'description', Webgen::Plugin.config[TestPlugin.name].params['name'].description )

    @x.param_set( 'name', Test2Plugin )
    assert_equal( Test2Plugin, @x.param( 'name' ) )
    @x2.param_set( 'name', TestPlugin )
    assert_equal( TestPlugin, @x.param( 'name' ) )
  end

  def test_getter_methods
    assert_equal( @x, Webgen::Plugin['plugin'] )
    assert_equal( TestPlugin, @x.param( 'name' ) )
    assert( @x.param?( 'name' ) )
    assert_equal( nil, @x.param( 'noname' ) )
    assert( !@x.param?( 'noname ' ) )

    assert_equal( TestPlugin, @x2.param( 'name' ) )
    assert( @x2.param?( 'name' ) )
    assert_equal( nil, @x2.param( 'noname' ) )
    assert( !@x2.param?( 'noname ' ) )
  end

end
