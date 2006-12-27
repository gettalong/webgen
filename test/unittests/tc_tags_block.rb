require 'webgen/test'
require 'webgen/node'

class BlockTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/block.rb',
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/page.rb',
  ]
  plugin_to_test 'Tag/Block'


  def test_process_tag
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    page_node = root.resolve_node('index.en.page')

    assert_equal( ["5 * 3 = 15", [page_node]], @plugin.process_tag( 'block', [page_node] ) )
    assert_equal( ["5 * 3 = 15", [page_node]], @plugin.process_tag( 'block', [page_node, page_node] ) )
    page_node['useERB'] = false
    assert_equal( ["5 * 3 = <%= 5*3 %>", [page_node]], @plugin.process_tag( 'block', [page_node] ) )

    set_config( 'blockName' => 'unknown' )
    assert_equal( '', @plugin.process_tag( 'block', [page_node] ) )
  end

end
