require 'fileutils'
require 'webgen/test'
require 'webgen/node'
require 'webgen/config'

class FileCopyHandlerTest < Webgen::FileHandlerTestCase

  plugin_files [
    'webgen/plugins/filehandlers/filehandler.rb',
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/copy.rb'
  ]
  plugin_to_test 'FileHandlers::FileCopyHandler'

  SAMPLE_SITE = BASE_FIXTURE_PATH + 'sample_site/'

  def setup
    super
    @manager.plugin_config = self
  end

  def param_for_plugin( plugin_name, param )
    case [plugin_name, param]
    when ['CorePlugins::Configuration', 'srcDir'] then SAMPLE_SITE + 'src'
    when ['CorePlugins::Configuration', 'outDir'] then SAMPLE_SITE + 'out'
    else raise Webgen::PluginParamNotFound.new( plugin_name, param )
    end
  end

  def test_create_node
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }
    src_file = File.join( param_for_plugin( 'CorePlugins::Configuration', 'srcDir' ), 'file1.page' )
    file = @plugin.create_node( src_file, root )
    assert_equal( 'file1.page', file.path )
    assert_equal( 'file1.page', file['title'] )
    assert_equal( src_file, file.node_info[:src] )
    assert_equal( @plugin, file.node_info[:processor] )

    assert_same( file, @plugin.create_node( src_file, root ) )
  end

  def test_write_node
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }
    src_file = File.join( param_for_plugin( 'CorePlugins::Configuration', 'srcDir' ), 'file1.page' )
    file = @plugin.create_node( src_file, root )

    file.write_node
    assert( File.exists?( file.full_path ) )
    assert( !@manager['FileHandlers::FileHandler'].file_modified?( file.node_info[:src], file.full_path ) )
    FileUtils.touch( file.node_info[:src] )
    file.write_node
    assert( !@manager['FileHandlers::FileHandler'].file_modified?( file.node_info[:src], file.full_path ) )
  ensure
    FileUtils.rm_r( root.full_path, :force => true )
  end

end

