require 'webgen/test'
require 'webgen/node'

class LangbarTagTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/Langbar'


  def test_process_tag
    root = @manager['Core/FileHandler'].instance_eval { build_tree }

    node = root.resolve_node( 'index.en.html' )
    de_link = '<a href="index.de.html">de</a>'
    en_link = '<span>en</span>'
    check_results( node, "#{de_link} | #{en_link}", de_link, "#{de_link} | #{en_link}", de_link )

    node = root.resolve_node( 'file1.en.html' )
    link = '<span>en</span>'
    check_results( node, link, '', '', '' )
  end


  def check_results( node, both_true, both_false, first_false, second_false )
    @plugin.set_params( 'showSingleLang'=>true, 'showOwnLang'=>true )
    assert_equal( both_true, @plugin.process_tag( 'langbar', '', Context.new( {}, [node] ) ) )

    @plugin.set_params( 'showSingleLang'=>false, 'showOwnLang'=>false )
    assert_equal( both_false, @plugin.process_tag( 'langbar', '', Context.new( {}, [node] ) ) )

    @plugin.set_params( 'showSingleLang'=>false, 'showOwnLang'=>true )
    assert_equal( first_false, @plugin.process_tag( 'langbar', '', Context.new( {}, [node] ) ) )

    @plugin.set_params( 'showSingleLang'=>true, 'showOwnLang'=>false )
    assert_equal( second_false, @plugin.process_tag( 'langbar', '', Context.new( {}, [node] ) ) )
  end

end
