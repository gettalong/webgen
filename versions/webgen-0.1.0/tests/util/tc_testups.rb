require 'test/unit'
require 'util/ups'


class UPSTest < Test::Unit::TestCase

    class UPSTestclass < UPS::Plugin

        NAME = "testPlugin"

        attr_accessor :called

        def initialize
            @called = ''
        end

        def init
            @called = 'init'
        end

        def destroy
            @called = 'destroy'
        end

    end


    def setup
        @testclass = UPSTestclass.new
    end


    def test_registry
        @listenerCalled = false
        UPS::Registry.add_msg_listener(:PLUGIN_REGISTERED) do |name| @listenerCalled = true end
        UPS::Registry.add_msg_listener(:PLUGIN_UNREGISTERED) do |name| @listenerCalled = true end

        assert( UPS::Registry.register_plugin( UPSTestclass ) )
        assert( @listenerCalled, 'Listener not called' )
        assert_equal( 'init', UPS::Registry['testPlugin'].called )
        @listenerCalled = false

        assert( !UPS::Registry.register_plugin( UPSTestclass ) )
        assert( !@listenerCalled, 'Listener should not have been called' )
        @listenerCalled = false

        plugin = UPS::Registry['testPlugin']
        assert( UPS::Registry.unregister_plugin( UPSTestclass ) )
        assert( @listenerCalled, 'Listener not called' )
        assert_equal( 'destroy', plugin.called )
    end

end
