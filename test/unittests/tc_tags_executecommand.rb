require 'webgen/test'

class ExecuteCommandTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/executecommand.rb',
  ]
  plugin_to_test 'Tags::ExecuteCommandTag'


  def test_process_tag
    testtext = "<a href=\"\">Test</a>"
    set_config( 'command'=>"echo -n '#{testtext}'", 'processOutput'=>false, 'escapeHTML'=>false )
    assert_equal( testtext, @plugin.process_tag( 'executecommand', nil ) )

    set_config( 'command'=>"echo -n '#{testtext}'", 'processOutput'=>true, 'escapeHTML'=>false )
    assert_equal( testtext, @plugin.process_tag( 'executecommand', nil ) )

    set_config( 'command'=>"echo -n '#{testtext}'", 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( '&lt;a href=&quot;&quot;&gt;Test&lt;/a&gt;', @plugin.process_tag( 'executecommand', nil ) )

    set_config( 'command'=>"invalid_echo_command -n '#{testtext}'", 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( '', @plugin.process_tag( 'executecommand', nil ) )
  end

end
