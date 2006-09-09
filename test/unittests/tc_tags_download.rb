require 'webgen/test'
require 'webgen/node'

class DownloadTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/download.rb',
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/copy.rb',
  ]
  plugin_to_test 'Tags/DownloadTag'


  def test_process_tag
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    node = root.resolve_node( 'test.jpg' )

    assert_equal( '', @plugin.process_tag( 'sitemap', [node] ) )

    set_config( 'url' => 'test.jpg' )
    assert_equal( '<img class="webgen-file-icon" src="{resource: webgen-icons-image}" alt="File icon" />' +
                  '<a href="test.jpg">test.jpg</a> (5 Byte)',
                  @plugin.process_tag( 'sitemap', [node, node] ) )

    set_config( 'url' => 'test.jpg', 'alwaysShowDownloadIcon' => true )
    assert_equal( @plugin.instance_eval { download_icon } +
                  '<img class="webgen-file-icon" src="{resource: webgen-icons-image}" alt="File icon" />' +
                  '<a href="test.jpg">test.jpg</a> (5 Byte)',
                  @plugin.process_tag( 'sitemap', [node, node] ) )
  end

end
