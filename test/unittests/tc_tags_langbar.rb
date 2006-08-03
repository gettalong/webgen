require 'webgen/test'
require 'webgen/node'

class LangbarTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/langbar.rb',
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/page.rb',
  ]
  plugin_to_test 'Tags::LangbarTag'


  def test_process_tag
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }

    node = root.resolve_node( 'index.en.page' )
    de_link = '<a href="index.de.html">de</a>'
    en_link = '<a href="index.html">en</a>'
    check_results( node, "#{de_link} | #{en_link}", de_link, "#{de_link} | #{en_link}", de_link )

    node = root.resolve_node( 'file1.page' )
    link = '<a href="file1.html">en</a>'
    check_results( node, link, '', '', '' )
  end


  def check_results( node, both_true, both_false, first_false, second_false )
    set_config( 'showSingleLang'=>true, 'showOwnLang'=>true )
    assert_equal( both_true, @plugin.process_tag( 'langbar', [node] ) )

    set_config( 'showSingleLang'=>false, 'showOwnLang'=>false )
    assert_equal( both_false, @plugin.process_tag( 'langbar', [node] ) )

    set_config( 'showSingleLang'=>false, 'showOwnLang'=>true )
    assert_equal( first_false, @plugin.process_tag( 'langbar', [node] ) )

    set_config( 'showSingleLang'=>true, 'showOwnLang'=>false )
    assert_equal( second_false, @plugin.process_tag( 'langbar', [node] ) )
  end

end
