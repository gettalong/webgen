require 'webgen/test'

module CoreTests

  class CacheManagerTest < Webgen::PluginTestCase

    plugin_to_test 'Core/CacheManager'

    def test_get
      assert_equal( nil, @plugin.get(['test']) )
      assert( !@plugin.new_data.has_key?( 'test' ) )

      assert_equal( nil, @plugin.get(['test'], :value) )
      assert_equal( :value, @plugin.new_data['test'] )

      @plugin.new_data.clear
      @plugin.data['test'] = :value
      assert_equal( :value, @plugin.get(['test']) )
      assert_equal( :value, @plugin.new_data['test'] )
      assert_equal( :value, @plugin.get(['test'], :changed) )
      assert_equal( :changed, @plugin.new_data['test'] )

      @plugin.new_data.clear
      @plugin.data['test'] = :value
      assert_equal( :value, @plugin.get(['test'], :changed) )
      assert_equal( :changed, @plugin.new_data['test'] )

      @plugin.new_data.clear
      @plugin.data['test'] = :oldval
      @plugin.set( ['test'], :newval )
      assert_equal( :oldval, @plugin.get(['test']) )
      assert_equal( :newval, @plugin.new_data['test'] )
    end

  end

end
