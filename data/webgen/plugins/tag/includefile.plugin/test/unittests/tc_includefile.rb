require 'fileutils'
require 'tempfile'
require 'webgen/test'
require 'webgen/node'

class IncludeFileTagTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/IncludeFile'

  def test_process_tag
    parent = Node.new( nil, 'dir/' )
    parent.node_info[:src] = fixture_path
    node = Node.new( parent, 'testfile' )
    node.node_info[:src] = fixture_path( 'testfile' )

    content = File.read( fixture_path( 'testfile' ) )

    @plugin.set_params( 'filename'=>"testfile", 'processOutput'=>false, 'escapeHTML'=>false )
    assert_equal( [content, false], @plugin.process_tag( 'includeFile', '', Context.new( {}, [node] ) ) )

    @plugin.set_params( 'filename'=>"testfile", 'processOutput'=>true, 'escapeHTML'=>false )
    assert_equal( [content, true], @plugin.process_tag( 'includeFile', '', Context.new( {}, [node] ) ) )

    @plugin.set_params( 'filename'=>"testfile", 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( [CGI::escapeHTML(content), true], @plugin.process_tag( 'includeFile', '', Context.new( {}, [node] ) ) )

    @plugin.set_params( 'filename'=>"invalidfile", 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( ['', true], @plugin.process_tag( 'includeFile', '', Context.new( {}, [node] ) ) )

    file = Tempfile.new( 'webgen-test-file' )
    file.write('hallo')
    file.close
    @plugin.set_params( 'filename'=>file.path, 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( ['hallo', true], @plugin.process_tag( 'includeFile', '', Context.new( {}, [node] ) ) )
  end

end
