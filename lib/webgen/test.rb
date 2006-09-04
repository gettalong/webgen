require 'pp'
require 'test/unit'
require 'webgen/plugin'
require 'webgen/config'

module Webgen

  # Base class for all webgen test cases. It specifies some auxilary methods helpful when developing
  # tests.
  class TestCase < Test::Unit::TestCase

    def self.inherited( klass )
      path = caller[0][/^.*?:/][0..-2]
      dir, file = File.split( path )
      parent_path, unit_tests = File.split( dir )

      fpath = if dir == '.'
                File.join( '..', 'fixtures' )
              else
                File.join( parent_path, 'fixtures' )
              end

      klass.instance_variable_set( :@fixture_path, File.join( fpath, File.basename( file, '.*' ) ) )
      klass.instance_variable_set( :@base_fixture_path, fpath + '/' )
    end

    def self.suite
      if self == TestCase
        return Test::Unit::TestSuite.new('Webgen::TestCase')
      else
        super
      end
    end

    #TODO doc
    def self.path_helper( var, filename = nil )
      var = instance_variable_get( var )
      (filename.nil? ? var : File.join( var, filename ) )
    end


    # If +filename+ is not specified, returns the fixture path for the test case. If +filename+ is
    # specified, it is appended to the fixture path.
    def self.fixture_path( filename = nil )
      path_helper( :@fixture_path, filename )
    end

    # See TestCase.fixture_path
    def fixture_path( filename = nil )
      self.class.fixture_path( filename )
    end

    def self.base_fixture_path( filename = nil )
      path_helper( :@base_fixture_path, filename )
    end

    # See TestCase.base_fixture_path
    def base_fixture_path( filename = nil )
      self.class.base_fixture_path( filename )
    end

  end


  # Base class for all plugin test cases. It ensures that all needed plugins are loaded and
  # initalized before each test and that the original environment is restored afterwards.
  class PluginTestCase < TestCase

    class << self

      # Specifies +files+ as the plugin files which define the plugin which should be tested and its
      # dependencies.
      def plugin_files( files = nil )
        (files.nil? ? @plugin_files.to_a + ['webgen/plugins/coreplugins/configuration.rb'] : @plugin_files = files )
      end

      def plugin_to_test( plugin = nil )
        @plugin_name ||= nil
        (plugin.nil? ? @plugin_name : @plugin_name = plugin )
      end

    end

    # required stdlib files sothat no warnings etc. are shown when re-requiring files
    require 'set'
    require 'fileutils'
    # require coderay, it will not work anymore if the CodeRay constants gets removed...
    begin require 'coderay'; rescue LoadError; end

    def setup
      @loader = PluginLoader.new

      before = $".dup
      @constants = Object.constants.dup
      @webgen_constants = Webgen.constants.dup
      begin
        self.class.plugin_files.each {|p| @loader.load_from_file( p ) }
      rescue Exception => e
        puts "Caught exception during loading of plugins in #setup: #{e.message}"
      end
      @required_files = $".dup - before

      @manager = PluginManager.new( [@loader], @loader.plugins )
      if $VERBOSE
        @manager.logger = Webgen::Logger.new
        @manager.logger.level = ::Logger::DEBUG
      end
      @manager.plugin_config = self
      @manager.init

      if !@manager.plugins.has_key?( 'ContentConverters::DefaultContentConverter' )
        @manager.plugins['ContentConverters::DefaultContentConverter'] = Object.new
        def (@manager.plugins['ContentConverters::DefaultContentConverter']).registered_handlers
          {'default' => proc {|c| c}, 'textile' => proc {|c| c}}
        end
      end

      @plugin = @manager[self.class.plugin_to_test] if self.class.plugin_to_test
    end

    def teardown
      remove_consts( Object, Object.constants - @constants )
      remove_consts( Webgen, Webgen.constants - @webgen_constants )
      @required_files.each {|f| $".delete( f )}
      @manager = nil
      @loader = nil
      @plugin_files = nil
    end

    def self.sample_site( filename = '' )
      path_helper( :@base_fixture_path, File.join( 'sample_site', filename ) )
    end

    def sample_site( filename = '' )
      self.class.sample_site( filename )
    end

    def param_for_plugin( plugin_name, param )
      case [plugin_name, param]
      when ['CorePlugins::Configuration', 'srcDir'] then sample_site( Webgen::SRC_DIR )
      when ['CorePlugins::Configuration', 'outDir'] then sample_site( 'out' )
      when ['CorePlugins::Configuration', 'websiteDir'] then sample_site
      else raise Webgen::PluginParamNotFound.new( plugin_name, param )
      end
    end

    def find_in_sample_site
      files = Set.new
      Find.find( sample_site( Webgen::SRC_DIR ) ) do |path|
        Find.prune if File.basename( path ) =~ /^\./
        path += '/' if FileTest.directory?(path)
        files << path if yield( path )
      end
      files
    end

    def remove_consts( obj, constants )
      constants.each do |c|
        obj.remove_const( c )
      end
    end

    def self.suite
      if self == PluginTestCase
        return Test::Unit::TestSuite.new('Webgen::TestCase')
      else
        super
      end
    end

  end


  # Base class for all plugin test cases. It ensures that all needed plugins are loaded and
  # initalized before each test and that the original environment is restored afterwards.
  class TagTestCase < PluginTestCase

    def self.suite
      if self == TagTestCase
        return Test::Unit::TestSuite.new('Webgen::TestCase')
      else
        super
      end
    end

    def set_config( config )
      @plugin.set_tag_config( config, Dummy.new )
    end

  end

  class Dummy

    def method_missing( name, *args, &block )
      Dummy.new
    end

  end

end

class Module
  public :remove_const
end
