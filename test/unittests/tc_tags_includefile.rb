require 'webgen/test'
require 'webgen/node'

class IncludeFileTagTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/tags/includefile.rb',
  ]
  plugin_to_test 'Tags::IncludeFileTag'

  def setup
    super
    parent = Node.new( nil, 'dir/' )
    parent.node_info[:src] = fixture_path
    @node = Node. new( parent, 'testfile' )
    @node.node_info[:src] = fixture_path( 'testfile' )
  end

  def test_process_tag
    content = File.read( fixture_path( 'testfile' ) )

    set_config( 'filename'=>"testfile", 'processOutput'=>false, 'escapeHTML'=>false )
    assert_equal( content, @plugin.process_tag( 'includeFile', [@node] ) )

    set_config( 'filename'=>"testfile", 'processOutput'=>true, 'escapeHTML'=>false )
    assert_equal( content, @plugin.process_tag( 'includeFile', [@node] ) )

    set_config( 'filename'=>"testfile", 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( CGI::escapeHTML(content), @plugin.process_tag( 'includeFile', [@node] ) )

    set_config( 'filename'=>"invalidfile", 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( '', @plugin.process_tag( 'includeFile', [@node] ) )
  end

  #######
  private
  #######

  def set_config( config )
    @plugin.set_tag_config( config, @node )
  end

end
