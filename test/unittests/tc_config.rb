require 'test/unit'
require 'webgen/config'

class ConfigTest < Test::Unit::TestCase

  def test_constants
    assert_not_nil( Webgen::SUMMARY )
    assert_not_nil( Webgen::DESCRIPTION )
    assert_not_nil( Webgen::VERSION )
  end

  def test_data_dir
    assert_nothing_raised do
      assert_not_equal( '', Webgen.data_dir )
    end
  end

end
