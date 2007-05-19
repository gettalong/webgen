require 'webgen/test'
require 'webgen/website'


class FileConfiguratorTest < Webgen::TestCase

  def test_initialize
    assert_raise( Webgen::ConfigurationFileInvalid ) do
      Webgen::FileConfigurator.new( fixture_path( 'incorrect_structure.yaml' ) )
    end
    assert_raise( Webgen::ConfigurationFileInvalid ) do
      Webgen::FileConfigurator.new( fixture_path( 'incorrect_yaml.yaml' ) )
    end

    configfile = Webgen::FileConfigurator.new( fixture_path( 'missing.yaml' ) )
    assert_equal( {}, configfile.config )

    configfile = Webgen::FileConfigurator.for_website( fixture_path )
    assert_equal( {}, configfile.config )
  end

  def test_param
    configfile = Webgen::FileConfigurator.new( fixture_path( 'correct.yaml' ) )
    assert_kind_of( Hash, configfile.config )
    assert_equal( [false, 'value'], configfile.param( 'param', 'TestPlugin', nil ) )
    assert_equal( [false, nil], configfile.param( 'noparam', 'TestPlugin', nil ) )
    assert_equal( [false, nil], configfile.param( 'param', 'UnknownPlugin', nil ) )
  end

  def test_auto_default_meta_info_setter
    configfile = Webgen::FileConfigurator.new( fixture_path( 'correct.yaml' ) )
    assert_equal( [false, {'File/MyHandler'=>{'metainfo'=>'value'}}], configfile.param( 'defaultMetaInfo', 'Core/FileHandler', nil ) )

    configfile = Webgen::FileConfigurator.new( fixture_path( 'meta_info_test.yaml' ) )
    assert_equal( [false, {'metainfo'=>'value'}], configfile.param( 'defaultMetaInfo', 'Core/FileHandler', nil ) )
  end

end

class WebSiteTest < Webgen::TestCase

  def test_initialize
    website = Webgen::WebSite.new( 'dir' )
    assert_not_nil( website.plugin_manager )
    assert_equal( [website], website.plugin_manager.configurators )
  end

  def test_param
    website = Webgen::WebSite.new( 'dir' )
    path = File.expand_path( 'dir' )
    assert_equal( path, website.plugin_manager.param( 'websiteDir', 'Core/Configuration' ) )
    assert_equal( File.join( path, Webgen::SRC_DIR ), website.plugin_manager.param( 'srcDir', 'Core/Configuration' ) )
    assert_equal( File.join( path, 'output' ), website.plugin_manager.param( 'outDir', 'Core/Configuration' ) )

    assert_equal( [true, '/output'], website.param( 'outDir', 'Core/Configuration', '/output' ) )
    assert_equal( [true, 'C:\output'], website.param( 'outDir', 'Core/Configuration', 'C:\output' ) )
    assert_equal( [false, nil], website.param( 'param', 'UnknownPlugin', nil ) )
  end

end
