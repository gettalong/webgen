require 'test/unit'
require 'webgen/plugin'

module Webgen

  # Base class for all webgen test cases. It specifies some auxilary methods helpful when developing
  # tests.
  class TestCase < Test::Unit::TestCase

    def self.inherited( klass )
      path = caller[0][/^.*?:/][0..-2]
      dir, file = File.split( path )
      parent_path, unit_tests = File.split( dir )

      full_path = if dir == '.'
                    File.join( '..', 'fixtures', File.basename( file, '.*' ) )
                  else
                    File.join( parent_path, 'fixtures', File.basename( file, '.*' ) )
                  end

      klass.class_eval( "FIXTURE_PATH = '#{full_path}/'" )
    end

    def self.suite
      if self == TestCase
        return Test::Unit::TestSuite.new('Webgen::TestCase')
      else
        super
      end
    end

    # If +filename+ is not specified, returns the fixture path for the test case. If +filename+ is
    # specified, it is appended to the fixture path.
    def self.fixture_path( filename = nil )
      (filename.nil? ? self::FIXTURE_PATH : File.join( self::FIXTURE_PATH, filename ) )
    end

    # See TestCase.fixture_path
    def fixture_path( filename = nil )
      self.class.fixture_path( filename )
    end

  end


  class PluginTestCase < TestCase

    class << self

      # Specifies +files+ as the plugin files which define the plugin which should be tested and its
      # dependencies.
      def plugin_files( files = nil )
        (files.nil? ? @plugin_files : @plugin_files = files )
      end

      def plugin_to_test( plugin = nil)
        (plugin.nil? ? @plugin_name : @plugin_name = plugin )
      end

    end

    def setup
      @loader = PluginLoader.new
      self.class.plugin_files.each {|p| @loader.load_from_file( p ) }
      @manager = PluginManager.new( [@loader], @loader.plugins )
      @manager.init
      @plugin = @manager[self.class.plugin_to_test]
    end

    def teardown
      @loader.plugins.each do |p|
        mod = p.name[/^.*?(?=::)/]
        if mod.nil?
          Object.remove_const( p.name )
        elsif Object.const_defined?( mod )
          Object.remove_const( mod )
        end
      end
      self.class.plugin_files.each {|f| $".delete( f )}
      @manager = nil
      @loader = nil
      @plugin_files = nil
    end

    def self.suite
      if self == PluginTestCase
        return Test::Unit::TestSuite.new('Webgen::TestCase')
      else
        super
      end
    end

  end

end

class Class
  public :remove_const
end
