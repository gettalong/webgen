require 'webgen/config'
require 'test/unit'
require 'webgen/plugin'

module Webgen

  # Base class for all webgen test cases. It specifies some auxilary methods helpful when developing
  # tests.
  class TestCase < Test::Unit::TestCase

    # Sets the base fixture path and the fixture path for the test case.
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

    # Reimplemented to hide the base test case.
    def self.suite
      if self == TestCase
        return Test::Unit::TestSuite.new('Webgen::TestCase')
      else
        super
      end
    end

    # Helper method for retrieving a path name with an optionally appended filename.
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

    # Returns the base fixture path for the test case. If +filename+ is specified, it is appended to
    # the base fixture path.
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
  #
  # In the #setup method all plugin bundles distributed with webgen are loaded. If a plugin test
  # case needs other plugin bundles, use the environment variable +WEBGEN_PLUGIN_BUNDLES+ to specify
  # additional directories (comma separated) containing plugin bundles.
  class PluginTestCase < TestCase

    class << self

      # The name of the plugin which should be tested.
      def plugin_to_test( plugin = nil )
        @plugin_name ||= nil
        (plugin.nil? ? @plugin_name : @plugin_name = plugin )
      end

    end

    # Initializes the plugin manager instance (available through <tt>@manager</tt>) and the plugin
    # specified with PluginTestCase.plugin_to_test (available throught <tt>@plugin</tt>). Respects
    # the +WEBGEN_PLUGIN_BUNDLES+ environment variable.
    def setup
      @manager = PluginManager.new( [self], nil )
      begin
        @manager.load_all_plugin_bundles( File.join( Webgen.data_dir, Webgen::PLUGIN_DIR ) )
        ENV['WEBGEN_PLUGIN_BUNDLES'].to_s.split(/,/).each do |bundle|
          @manager.load_all_plugin_bundles( bundle )
        end
      rescue Exception => e
        puts "Caught exception during loading of plugins in #setup: #{e.message} - #{e.backtrace.first}"
      end

      if $VERBOSE
        @manager.logger = Webgen::Logger.new
        @manager.logger.level = ::Logger::DEBUG
      end

      @plugin = @manager[self.class.plugin_to_test] if self.class.plugin_to_test
    end

    # Removes the plugin manager and plugin instance variables.
    def teardown
      @manager = nil
      @plugin = nil
    end

    # Returns the path to the sample website. If +filename+ is specified, it is appended to the
    # sample website path.
    def self.sample_site( filename = '' )
      path_helper( :@base_fixture_path, filename )
    end

    # See self.sample_site
    def sample_site( filename = '' )
      self.class.sample_site( filename )
    end

    # The instance acts as a configurator for the plugin manager created in the #setup method.
    def param( name, plugin, cur_val )
      case [plugin, name]
      when ['Core/Configuration', 'srcDir'] then [true, sample_site( Webgen::SRC_DIR )]
      when ['Core/Configuration', 'outDir'] then [true, sample_site( 'out' )]
      when ['Core/Configuration', 'websiteDir'] then [true, sample_site]
      else [false, cur_val]
      end
    end

    # Returns all paths in the sample website for which the block yields +true+.
    def find_in_sample_site
      files = Set.new
      Find.find( sample_site( Webgen::SRC_DIR ) ) do |path|
        Find.prune if File.basename( path ) =~ /^\./
        path += '/' if FileTest.directory?(path)
        files << path if yield( path )
      end
      files
    end

    # Reimplemented to hide the base test case.
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

