require 'fileutils'
require 'webgen/test'
require 'webgen/node'

class IncludeFileTagTest < Webgen::TagTestCase

  plugin_files [
                'webgen/plugins/coreplugins/resourcemanager.rb',
                'webgen/plugins/tags/includefile.rb',
               ]
  plugin_to_test 'Tag/IncludeFile'

  def test_process_tag
    parent = Node.new( nil, 'dir/' )
    parent.node_info[:src] = fixture_path
    node = Node. new( parent, 'testfile' )
    node.node_info[:src] = fixture_path( 'testfile' )

    content = File.read( fixture_path( 'testfile' ) )

    set_config( 'filename'=>"testfile", 'processOutput'=>false, 'escapeHTML'=>false )
    assert_equal( content, @plugin.process_tag( 'includeFile', [node] ) )
    assert_equal( false, @plugin.process_output? )

    set_config( 'filename'=>"testfile", 'processOutput'=>true, 'escapeHTML'=>false )
    assert_equal( content, @plugin.process_tag( 'includeFile', [node] ) )
    assert_equal( true, @plugin.process_output? )

    set_config( 'filename'=>"testfile", 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( CGI::escapeHTML(content), @plugin.process_tag( 'includeFile', [node] ) )

    set_config( 'filename'=>"testfile", 'processOutput'=>true, 'escapeHTML'=>false, 'highlight'=>'html' )
    assert_kind_of( String, @plugin.process_tag( 'includeFile', [node] ) )

    set_config( 'filename'=>"invalidfile", 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( '', @plugin.process_tag( 'includeFile', [node] ) )

    # test absolute file name
    begin
      name = "webgen-test-file-#{$$}.txt"
      full_name = File.join( '/tmp', name )
      FileUtils.mkdir_p( '/tmp' )
      File.open( full_name, 'w+' ) {|f| f.write('hallo')}
      set_config( 'filename'=>full_name, 'processOutput'=>true, 'escapeHTML'=>true )
      assert_equal( 'hallo', @plugin.process_tag( 'includeFile', [node] ) )
    ensure
      FileUtils.rm( full_name ) rescue ''
      FileUtils.rmdir( '/tmp' ) rescue ''
    end

  end

end
