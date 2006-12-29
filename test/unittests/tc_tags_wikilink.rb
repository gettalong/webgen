require 'webgen/test'
require 'webgen/node'

class WikiLinkTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/wikilink.rb',
  ]
  plugin_to_test 'Tag/WikiLink'


  def test_process_tag
    node = Node.new( nil, 'file1' )
    node['title'] = 'File1'

    assert_equal( '<a href="/wiki/wiki.pl?File1">File1</a>', @plugin.process_tag( 'wikilink', [node] ) )

    set_config( 'linkText' => 'File2', 'relURL'=>'File3&;' )
    assert_equal( '<a href="/wiki/wiki.pl?File3__">File2</a>', @plugin.process_tag( 'wikilink', [node] ) )
  end

end
