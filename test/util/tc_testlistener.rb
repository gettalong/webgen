require 'test/unit'
require 'util/listener'


class ListenerTest < Test::Unit::TestCase

    class ListenerTestclass
        include Listener

        def add_msg
            add_msg_name :testmsg
        end

        def del_msg
            del_msg_name :testmsg
        end

        def dispatch( msgname, args )
            dispatch_msg( msgname, args )
        end
    end


    def setup
        @testclass = ListenerTestclass.new
    end


    def test_message_handling
        assert_kind_of( Listener, @testclass )
        assert_nothing_raised do
            @testclass.del_msg
            @testclass.add_msg
            @testclass.add_msg
            @testclass.del_msg
        end
    end


    def msg_receiver( *args )
        @times += 1
        assert_equal( 1, args.length )
    end


    def test_message_passing
        assert_nothing_raised do
            @testclass.add_msg_listener( :testmsg, "hello" )
        end

        @testclass.add_msg

        assert_raise( NoMethodError ) do
            @testclass.add_msg_listener( :testmsg, "hello" )
        end

        @times = 0
        assert_nothing_raised do
            @testclass.add_msg_listener( :testmsg, method(:msg_receiver) )
            @testclass.add_msg_listener( :testmsg ) do |*args|
                msg_receiver *args
            end
        end
        assert_equal( 0, @times )

        @testclass.dispatch( :testmsg, 'hello' )
        assert_equal( 2, @times, 'some receiver objects were not called'  )
    end

end
