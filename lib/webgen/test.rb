require 'test/unit'

module Webgen

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

    def self.fixture_path( filename = nil )
      (filename.nil? ? self::FIXTURE_PATH : File.join( self::FIXTURE_PATH, filename ) )
    end

    def fixture_path( filename = nil )
      self.class.fixture_path( filename )
    end

  end

end
