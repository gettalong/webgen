require 'webgen/test'

class RDocConverterTest < Webgen::PluginTestCase

  plugin_to_test 'ContentProcessor/RDoc'

  def test_initialization
    assert_not_nil( @plugin )
  end

  def test_process
    context = Context.new( {}, [])
    context.content = '* hello'
    assert_nothing_raised { @plugin.process( context ) }
  end

end
