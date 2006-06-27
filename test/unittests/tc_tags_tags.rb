require 'webgen/test'

class TagProcessorTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/tags/tags.rb',
  ]
  plugin_to_test 'Tags::TagProcessor'

  def test_process
    flunk
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
    add_tag
    assert_not_nil( @plugin.instance_eval { processor_for_tag( 'test' ) } )
  end

  def test_registered_tags
    assert_equal( {}, @plugin.instance_eval { registered_tags } )
    add_tag
    assert_equal( {'test'=>@manager['TestTag']}, @plugin.instance_eval { registered_tags } )
  end

  #######
  private
  #######

  def check_returned_tags( content, count )
    i = 0
    @plugin.instance_eval { replace_tags( content, nil ) {|tag, data| i += 1} }
    assert_equal( count, i, content )
  end

  def add_tag
    @loader.load_from_block do
      self.class.module_eval "class ::TestTag < Tags::DefaultTag; register_tag 'test'; end"
    end
    @manager.add_plugin_classes( @loader.plugins )
    @manager.init
  end

end


class DefaultTagTest < Webgen::PluginTestCase

  class Dummy

    def method_missing( name, *args, &block )
      Dummy.new
    end

  end

  plugin_files [
                'webgen/plugins/tags/tags.rb',
                fixture_path( 'testtag.rb' )
               ]
  plugin_to_test 'Tags::DefaultTag'

  def test_tags
    assert_equal( ['test', 'test1'], @manager['Testing::TestTag'].tags )
  end

  def test_set_tag_config
    @manager['Testing::TestTag'].set_tag_config( nil, Dummy.new )
    assert_equal( nil, @manager['Testing::TestTag'].param( 'test' ) )

    @manager['Testing::TestTag'].set_tag_config( {}, Dummy.new )
    assert_equal( nil, @manager['Testing::TestTag'].param( 'test' ) )

    @manager['Testing::TestTag'].set_tag_config( 'test_value', Dummy.new )
    assert_equal( 'test_value', @manager['Testing::TestTag'].param( 'test' ) )

    @manager['Testing::TestTag'].set_tag_config( {'test' => 'test_value'}, Dummy.new )
    assert_equal( 'test_value', @manager['Testing::TestTag'].param( 'test' ) )
  end

  def test_process_tag
    assert_raises( NotImplementedError ) { Tags::DefaultTag.new( @manager ).process_tag( nil, nil ) }
  end

end
