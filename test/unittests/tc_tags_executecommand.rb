require 'webgen/test'
require 'rbconfig'

class ExecuteCommandTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/executecommand.rb',
  ]
  plugin_to_test 'Tags::ExecuteCommandTag'


  def test_process_tag
    testtext = "a\"b\""
    set_config( 'command'=>echo_cmd( testtext ), 'processOutput'=>false, 'escapeHTML'=>false )
    assert_equal( testtext, @plugin.process_tag( 'executecommand', nil ).chomp.strip )

    set_config( 'command'=>echo_cmd( testtext ), 'processOutput'=>true, 'escapeHTML'=>false )
    assert_equal( testtext, @plugin.process_tag( 'executecommand', nil ).chomp.strip )

    set_config( 'command'=>echo_cmd( testtext ), 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( 'a&quot;b&quot;', @plugin.process_tag( 'executecommand', nil ).chomp.strip )

    set_config( 'command'=>"invalid_echo_command -n '#{testtext}'", 'processOutput'=>true, 'escapeHTML'=>true )
    assert_equal( '', @plugin.process_tag( 'executecommand', nil ).chomp.strip )
  end

  def echo_cmd( data )
    (Config::CONFIG['arch'].include?( 'mswin32' ) ?  "echo #{data}" : "echo '#{data}'")
  end

end
