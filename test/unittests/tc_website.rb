require 'webgen/test'
require 'webgen/website'

module DirectoryInfoUtils

  def check_dir_info( name, dir_info )
    assert_kind_of( Webgen::DirectoryInfo, dir_info )
    assert_equal( name, dir_info.name )
    assert_kind_of( String, dir_info.infos['description'] )
    assert_kind_of( String, dir_info.infos['creator'] )
    assert_kind_of( Hash, dir_info.infos )
    assert_kind_of( Array, dir_info.files )
  end

end

class WebSiteTemplateTest < Webgen::TestCase

  include DirectoryInfoUtils

  def test_all
    t = Webgen::WebSiteTemplate.entries
    assert( t.size >= 1 )
    assert_kind_of( Hash, t )
    assert_kind_of( Webgen::WebSiteTemplate, t['default'] )
    t.each {|name, template| check_dir_info( name, template )}
  end

end

class WebSiteStyleTest < Webgen::TestCase

  include DirectoryInfoUtils

  def test_all
    t = Webgen::WebSiteStyle.entries
    assert( t.size >= 1 )
    assert_kind_of( Hash, t )
    assert_kind_of( Webgen::WebSiteStyle, t['default'] )
    t.each {|name, style| check_dir_info( name, style )}
    assert_equal( 2, t['default'].files.length )
  end

end


class WebSiteTest < Webgen::TestCase

  def test_render
    #TODO
  end

  def test_create_website
    #TODO
  end

end


class ConfigurationFileTest < Webgen::TestCase

  def test_param_for_plugin
    configfile = Webgen::ConfigurationFile.new( fixture_path( 'correct.yaml' ) )
    assert_kind_of( Hash, configfile.config )
    assert_equal( 'value', configfile.param_for_plugin( 'TestPlugin', 'param' ) )

    assert_raise( Webgen::ConfigurationFileInvalid ) do
      Webgen::ConfigurationFile.new( fixture_path( 'incorrect_structure.yaml' ) )
    end
    assert_raise( Webgen::ConfigurationFileInvalid ) do
      Webgen::ConfigurationFile.new( fixture_path( 'incorrect_yaml.yaml' ) )
    end

    configfile = Webgen::ConfigurationFile.new( fixture_path( 'missing.yaml' ) )
    assert_equal( {}, configfile.config )
  end


end
