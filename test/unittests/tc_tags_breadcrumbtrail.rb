require 'webgen/test'
require 'webgen/node'

class BreadcrumbTrailTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/breadcrumbtrail.rb',
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/page.rb',
  ]
  plugin_to_test 'Tags/BreadcrumbTrailTag'


  def test_process_tag
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    node = root.resolve_node( 'dir1/dir11/file111.en.page' )

    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <a href="file111.html">File111</a>',
                  @plugin.process_tag( 'breadcrumbTrail', [node] ) )
  end

end
