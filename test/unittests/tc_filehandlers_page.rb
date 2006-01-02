=begin
require 'test/unit'
require 'webgen/plugins/coreplugins/configuration'
require 'setup'

class PageHandlerTest < Test::Unit::TestCase

  Webgen::Plugin['Configuration'].init_all

  class TestPageHandler < ::FileHandlers::PageFileHandler
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
                                        'srcName' => 'default.page',
                                        'name' => 'default', 'orderInfo' => 0,
                                        'title' => 'Default', 'useLangPart' => false } ) )
    analyse_file_name( OpenStruct.new( {'lang' => 'de',
                                        'srcName' => 'default.de.page',
                                        'name' => 'default', 'orderInfo' => 0,
                                        'title' => 'Default', 'useLangPart' => true } ) )
    analyse_file_name( OpenStruct.new( {'lang' => 'eo',
                                        'srcName' => '12.Hello webpage_hello.eo.page',
                                        'name' => 'Hello webpage_hello', 'orderInfo' => 12,
                                        'title' => 'Hello webpage hello', 'useLangPart' => true } ) )
    analyse_file_name( OpenStruct.new( {'lang' => Webgen::Plugin['Configuration']['lang'],
                                        'srcName' => 'default.e.page',
                                        'name' => 'default', 'orderInfo' => 0,
                                        'title' => 'Default', 'useLangPart' => false } ) )
    analyse_file_name( OpenStruct.new( {'lang' => Webgen::Plugin['Configuration']['lang'],
                                        'srcName' => 'default.eadd.page',
                                        'name' => 'default', 'orderInfo' => 0,
                                        'title' => 'Default', 'useLangPart' => false } ) )
  end

end
=end
