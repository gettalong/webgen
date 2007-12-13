require 'webgen/test'
require 'time'

class DateTagTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/Date'

  def test_process_tag
    assert_not_nil( Time.parse( @plugin.process_tag( 'date', '', Context.new( {}, [] ) ) ) )
  end

end
