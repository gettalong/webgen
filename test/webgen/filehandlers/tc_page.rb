require 'test/unit'
require 'webgen/configuration'
require 'setup'

class PageHandlerTest < Test::Unit::TestCase

  Webgen::Plugin['Configuration'].init_all( {} )

  class TestPageHandler < ::FileHandlers::PageHandler
    def test_analyse_file_name( name)
      analyse_file_name( name )
    end
  end

  def setup
    @o = TestPageHandler.new
  end

  def analyse_file_name( struct )
    assert_equal( struct, @o.test_analyse_file_name( struct.srcName ) )
  end

  def test_analyse_file_name
    analyse_file_name( OpenStruct.new( {'lang' => Webgen::Plugin['Configuration']['lang'],
                                        'baseName' => 'default.html', 'srcName' => 'default.page',
                                        'urlName' => 'default.html', 'menuOrder' => 0,
                                        'title' => 'Default' } ) )
    analyse_file_name( OpenStruct.new( {'lang' => 'de',
                                        'baseName' => 'default.html', 'srcName' => 'default.de.page',
                                        'urlName' => 'default.de.html', 'menuOrder' => 0,
                                        'title' => 'Default' } ) )
    analyse_file_name( OpenStruct.new( {'lang' => 'eo',
                                        'baseName' => 'Hello webpage_hello.html', 'srcName' => '12.Hello webpage_hello.eo.page',
                                        'urlName' => 'Hello webpage_hello.eo.html', 'menuOrder' => 12,
                                        'title' => 'Hello webpage hello' } ) )
    analyse_file_name( OpenStruct.new( {'lang' => Webgen::Plugin['Configuration']['lang'],
                                        'baseName' => 'default.html', 'srcName' => 'default.e.page',
                                        'urlName' => 'default.html', 'menuOrder' => 0,
                                        'title' => 'Default' } ) )
    analyse_file_name( OpenStruct.new( {'lang' => Webgen::Plugin['Configuration']['lang'],
                                        'baseName' => 'default.html', 'srcName' => 'default.eadd.page',
                                        'urlName' => 'default.html', 'menuOrder' => 0,
                                        'title' => 'Default' } ) )
  end

end
