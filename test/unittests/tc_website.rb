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

class SampleDirectoryInfo < Webgen::DirectoryInfo; end

class DirectoryInfoTest < Webgen::TestCase

  SampleDirectoryInfo.const_set( :BASE_PATH, fixture_path )

  def test_initialize
    assert_raise( ArgumentError ) { SampleDirectoryInfo.new( __FILE__ ) }
    assert_raise( Errno::ENOENT ) { SampleDirectoryInfo.new( './' ) }

    SampleDirectoryInfo.remove_const( :BASE_PATH )
    SampleDirectoryInfo.const_set( :BASE_PATH, fixture_path( 'testdir' ) )
    assert_raise( ArgumentError ) { SampleDirectoryInfo.new( 'falsedir' ) }
    SampleDirectoryInfo.remove_const( :BASE_PATH )
    SampleDirectoryInfo.const_set( :BASE_PATH, fixture_path )

    assert_nothing_raised { SampleDirectoryInfo.new( 'testdir' ) }
    assert_equal( 'testdir', SampleDirectoryInfo.new('testdir').name )
  end

  def test_path
    assert_equal( File.expand_path( File.join( fixture_path, 'testdir' ) ), SampleDirectoryInfo.new( 'testdir' ).path )
  end

  def test_entries
    entries = SampleDirectoryInfo.entries
    assert_kind_of( Hash, entries )
    assert_equal( 1, entries.length )
    assert( entries.has_key?( 'testdir' ) )
    assert_kind_of( SampleDirectoryInfo, entries['testdir'] )
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

  SAMPLE_SITE = fixture_path( '../sample_site/' )

  def param_for_plugin( plugin_name, param )
    if [plugin_name, param] == ['Core/Configuration', 'lang']
      'eo'
    else
      raise Webgen::PluginParamNotFound.new( plugin_name, param )
    end
  end

  def test_initialize
    plugin_sandbox do
      # Test repeated initialization
      website = Webgen::WebSite.new( SAMPLE_SITE )
      website = Webgen::WebSite.new( SAMPLE_SITE )
    end
  end

  def test_param_for_plugin
    plugin_sandbox do
      # without plugin_config
      website = Webgen::WebSite.new( SAMPLE_SITE )
      path = File.expand_path( SAMPLE_SITE )
      assert_equal( File.join( path, Webgen::SRC_DIR ), website.manager.param_for_plugin( 'Core/Configuration', 'srcDir' ) )
      assert_equal( File.join( path, 'output' ), website.manager.param_for_plugin( 'Core/Configuration', 'outDir' ) )
      assert_equal( path, website.manager.param_for_plugin( 'Core/Configuration', 'websiteDir' ) )
      assert_equal( 'en', website.manager.param_for_plugin( 'Core/Configuration', 'lang' ) )

      # with plugin_config
      website = Webgen::WebSite.new( SAMPLE_SITE, self )
      assert_equal( 'eo', website.manager.param_for_plugin( 'Core/Configuration', 'lang' ) )
    end
  end

  def test_create_website
    assert_raise( ArgumentError ) { Webgen::WebSite.create_website( File.join( SAMPLE_SITE, 'test' ), 'invalid_name' ) }
    assert_raise( ArgumentError ) { Webgen::WebSite.create_website( File.join( SAMPLE_SITE, 'test' ), 'default', 'invalid_name' ) }
    assert_raise( ArgumentError ) { Webgen::WebSite.create_website( SAMPLE_SITE, 'default', 'default' ) }
  end

  #######
  private
  #######

  def plugin_sandbox
    Webgen::DEFAULT_PLUGIN_LOADER.load_from_file( 'webgen/plugins/coreplugins/configuration' )
    yield
  ensure
    Webgen.remove_const( :DEFAULT_PLUGIN_LOADER )
    Webgen.remove_const( :DEFAULT_WRAPPER_MODULE )
    Webgen.const_set( :DEFAULT_WRAPPER_MODULE, Module.new )
    Webgen.const_set( :DEFAULT_PLUGIN_LOADER, Webgen.init_default_plugin_loader( Webgen::DEFAULT_WRAPPER_MODULE ) )
  end

end


class ConfigurationFileTest < Webgen::TestCase

  def test_initialize
    assert_raise( Webgen::ConfigurationFileInvalid ) do
      Webgen::ConfigurationFile.new( fixture_path( 'incorrect_structure.yaml' ) )
    end
    assert_raise( Webgen::ConfigurationFileInvalid ) do
      Webgen::ConfigurationFile.new( fixture_path( 'incorrect_yaml.yaml' ) )
    end

    configfile = Webgen::ConfigurationFile.new( fixture_path( 'missing.yaml' ) )
    assert_equal( {}, configfile.config )
  end

  def test_param_for_plugin
    configfile = Webgen::ConfigurationFile.new( fixture_path( 'correct.yaml' ) )
    assert_kind_of( Hash, configfile.config )
    assert_equal( 'value', configfile.param_for_plugin( 'TestPlugin', 'param' ) )
    assert_raise( Webgen::PluginParamNotFound ) { configfile.param_for_plugin( 'TestPlugin', 'noparam' ) }
    assert_raise( Webgen::PluginParamNotFound ) { configfile.param_for_plugin( 'UnknownPlugin', 'param' ) }
  end

  def test_auto_default_meta_info_setter
    configfile = Webgen::ConfigurationFile.new( fixture_path( 'correct.yaml' ) )
    assert_equal( {'File/MyHandler'=>{'metainfo'=>'value'}}, configfile.param_for_plugin( 'Core/FileHandler', 'defaultMetaInfo' ) )

    configfile = Webgen::ConfigurationFile.new( fixture_path( 'meta_info_test.yaml' ) )
    assert_equal( {'metainfo'=>'value'}, configfile.param_for_plugin( 'Core/FileHandler', 'defaultMetaInfo' ) )
  end

end
