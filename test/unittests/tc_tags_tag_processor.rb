require 'webgen/test'
require 'webgen/node'

class TagProcessorTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/coreplugins/resourcemanager.rb',
    'webgen/plugins/tags/tag_processor.rb'
  ]
  plugin_to_test 'Core/TagProcessor'

  def test_process
    parent = Node.new( nil, fixture_path )
    parent.node_info[:src] = fixture_path
    node = Node.new( parent, 'testtag.rb' )
    node.meta_info['test'] = 'test'

    content = "{includeFile: test_file1}"
    assert_equal( '', @plugin.process( content, [node] ) )
    add_tag( 'webgen/plugins/tags/includefile.rb' )
    add_tag( 'webgen/plugins/tags/meta.rb' )

    content = "{includeFile: {filename: test_file1, processOutput: true}}"
    assert_equal( 'test', @plugin.process( content, [node] ) )

    content = "{includeFile: {filename: test_file1, processOutput: false}}"
    assert_equal( '{test:}', @plugin.process( content, [node] ) )
  end

  def test_replace_tags
    check_returned_tags( 'sdfsdf{asd', 0 )
    check_returned_tags( 'sdfsdf}asd', 0 )
    check_returned_tags( 'sdfsdf{asd}', 0 )
    check_returned_tags( 'sdfsdf{asd: {}as', 0 )
    check_returned_tags( 'sdfsdf{test:}{test1: }', 2 )
    check_returned_tags( 'sdfsdf{test:}\\{test1: }', 1 )
    check_returned_tags( 'sdfsdf {test:}asdffd \\{test1: }asdf{tst: asdf}', 2 )
  end

  def test_processor_for_tag
    assert_nil( @plugin.instance_eval { processor_for_tag( 'test' ) } )
    assert_nil( @plugin.instance_eval { processor_for_tag( :default ) } )
    add_tag( 'webgen/plugins/tags/meta.rb' )
    assert_not_nil( @plugin.instance_eval { processor_for_tag( :default ) } )
  end

  def test_registered_tags
    assert_equal( {'resource'=>@manager['Tags/ResourceTag']}, @plugin.instance_eval { registered_tags } )
    add_tag( 'webgen/plugins/tags/meta.rb' )
    assert_equal( {'resource'=>@manager['Tags/ResourceTag'], :default=>@manager['Tags/MetaTag']}, @plugin.instance_eval { registered_tags } )
  end

  #######
  private
  #######

  def check_returned_tags( content, count )
    i = 0
    @plugin.instance_eval { replace_tags( content, Webgen::Dummy.new ) {|tag, data| i += 1} }
    assert_equal( count, i, content )
  end

  def add_tag( file )
    @loader.load_from_file( file )
    @manager.add_plugin_classes( @loader.plugin_classes )
    @manager.init
  end

end


class DefaultTagTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/tags/tag_processor.rb',
                fixture_path( 'testtag.rb' )
               ]
  plugin_to_test 'Tags/DefaultTag'

  def test_tags
    assert_equal( ['test', 'test1'], @manager['Testing/TestTag'].tags )
  end

  def test_set_tag_config
    @manager['Testing/TestTag'].set_tag_config( nil, Webgen::Dummy.new )
    assert_equal( nil, @manager['Testing/TestTag'].param( 'test' ) )

    @manager['Testing/TestTag'].set_tag_config( {}, Webgen::Dummy.new )
    assert_equal( nil, @manager['Testing/TestTag'].param( 'test' ) )

    @manager['Testing/TestTag'].set_tag_config( 'test_value', Webgen::Dummy.new )
    assert_equal( 'test_value', @manager['Testing/TestTag'].param( 'test' ) )

    @manager['Testing/TestTag'].set_tag_config( {'test' => 'test_value'}, Webgen::Dummy.new )
    assert_equal( 'test_value', @manager['Testing/TestTag'].param( 'test' ) )
  end

  def test_process_tag
    assert_raises( NotImplementedError ) { @wrapper::Tags::DefaultTag.new( @manager ).process_tag( nil, nil ) }
  end

end
