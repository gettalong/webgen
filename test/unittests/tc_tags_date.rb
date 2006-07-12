require 'webgen/test'

class DateTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/date.rb',
  ]
  plugin_to_test 'Tags::DateTag'


  def test_process_tag
    assert_not_nil( Time.parse( @plugin.process_tag( 'date', nil ) ) )
  end

end
