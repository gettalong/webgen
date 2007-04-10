require 'webgen/test'
require 'webgen/config'

class ConfigTest < Webgen::TestCase

  def test_constants
    assert_not_nil( Webgen::SUMMARY )
    assert_not_nil( Webgen::DESCRIPTION )
    assert_not_nil( Webgen::VERSION )
  end

  def test_data_dir
    assert_nothing_raised do
      assert_equal( File.expand_path( File.join( File.dirname( __FILE__ ), '..', '..', 'data', 'webgen' ) ), Webgen.data_dir )
    end
  end

end
