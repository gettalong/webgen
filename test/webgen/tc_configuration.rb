require 'test/unit'
require 'webgen/configuration'
require 'setup'

class PluginTest < Test::Unit::TestCase

  class TestPlugin < Webgen::Plugin

    summary "summary"
    description "description"
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
    @x = Webgen::Plugin.config[TestPlugin].obj = TestPlugin.new
    @x2 = Test2Plugin.new
  end


  def test_class_inherited
    assert_instance_of( OpenStruct, Webgen::Plugin.config[TestPlugin] )
    assert_equal( TestPlugin, Webgen::Plugin.config[TestPlugin].klass )
  end

  def test_setter_methods
    ['summary','description'].each do |text|
      assert_equal( text, Webgen::Plugin.config[TestPlugin].send( text ) )
    end
    assert_nil( Webgen::Plugin.config[TestPlugin].dependencies )
    assert_equal( nil, Webgen::Plugin.config[TestPlugin].dependencies )
    assert_instance_of( Hash, Webgen::Plugin.config[TestPlugin].params )
    assert_equal( 'name', Webgen::Plugin.config[TestPlugin].params['name'].name )
    assert_equal( TestPlugin, Webgen::Plugin.config[TestPlugin].params['name'].value )
    assert_equal( TestPlugin, Webgen::Plugin.config[TestPlugin].params['name'].default )
    assert_equal( 'description', Webgen::Plugin.config[TestPlugin].params['name'].description )

    @x.param_set( 'name', Test2Plugin )
    assert_equal( Test2Plugin, @x.param( 'name' ) )
    @x2.param_set( 'name', TestPlugin )
    assert_equal( TestPlugin, @x.param( 'name' ) )
  end

  def test_getter_methods
    assert_equal( @x, Webgen::Plugin['TestPlugin'] )
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
