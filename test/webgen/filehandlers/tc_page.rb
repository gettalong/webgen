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
                                        'baseName' => 'default.page', 'srcName' => 'default.page',
                                        'name' => 'default', 'menuOrder' => 0,
                                        'title' => 'Default', 'useLangPart' => false } ) )
    analyse_file_name( OpenStruct.new( {'lang' => 'de',
                                        'baseName' => 'default.page', 'srcName' => 'default.de.page',
                                        'name' => 'default', 'menuOrder' => 0,
                                        'title' => 'Default', 'useLangPart' => true } ) )
    analyse_file_name( OpenStruct.new( {'lang' => 'eo',
                                        'baseName' => 'Hello webpage_hello.page', 'srcName' => '12.Hello webpage_hello.eo.page',
                                        'name' => 'Hello webpage_hello', 'menuOrder' => 12,
                                        'title' => 'Hello webpage hello', 'useLangPart' => true } ) )
    analyse_file_name( OpenStruct.new( {'lang' => Webgen::Plugin['Configuration']['lang'],
                                        'baseName' => 'default.page', 'srcName' => 'default.e.page',
                                        'name' => 'default', 'menuOrder' => 0,
                                        'title' => 'Default', 'useLangPart' => false } ) )
    analyse_file_name( OpenStruct.new( {'lang' => Webgen::Plugin['Configuration']['lang'],
                                        'baseName' => 'default.page', 'srcName' => 'default.eadd.page',
                                        'name' => 'default', 'menuOrder' => 0,
                                        'title' => 'Default', 'useLangPart' => false } ) )
  end

end
