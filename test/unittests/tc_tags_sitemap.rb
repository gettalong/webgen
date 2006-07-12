require 'webgen/test'
require 'webgen/node'

class SitemapTagTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/tags/sitemap.rb',
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/contentconverters/textile.rb',
    'webgen/plugins/filehandlers/page.rb',
  ]
  plugin_to_test 'Tags::SitemapTag'


  def test_process_tag
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }

    node = root.resolve_node( 'file1.page' )
    assert_equal( '<ul><li><a href="dir1/">Dir1</a><ul><li><a href="dir1/dir11/index.html">Dir11</a>' +
                  '<ul><li><a href="dir1/dir11/file111.html">File111</a></li></ul></li>' +
                  '<li><a href="dir1/file11.html">File11</a></li></ul></li></ul>',
                  @plugin.process_tag( 'sitemap', [node] ) )

    set_config( 'honorInMenu' => false )
    assert_equal( '<ul><li><a href="dir1/">Dir1</a><ul><li><a href="dir1/dir11/index.html">Dir11</a>' +
                  '<ul><li><a href="dir1/dir11/file111.html">File111</a></li></ul></li>' +
                  '<li><a href="dir1/file11.html">File11</a></li></ul></li>' +
                  '<li><a href="file1.html">File1</a></li><li><a href="index.html">Index</a></li></ul>',
                  @plugin.process_tag( 'sitemap', [node] ) )
  end

  #######
  private
  #######

  def set_config( config )
    @plugin.set_tag_config( config, Webgen::Dummy.new )
  end

end
