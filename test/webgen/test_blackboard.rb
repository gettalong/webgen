# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/blackboard'

class TestBlackboard < MiniTest::Unit::TestCase

  def setup
    @blackboard = Webgen::Blackboard.new
  end

  def test_add_listener
    assert_raises(ArgumentError) { @blackboard.add_listener(:test) }
    @blackboard.add_listener(:test) { throw :called }
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }

    msgs = []
    @blackboard.add_listener(:other, 'test') { msgs << 'test' }
    @blackboard.add_listener(:other, nil, :before => 'test') { msgs << 'before' }
    @blackboard.add_listener(:other, nil, :before => 'non-existing') { msgs << 'after 2' }
    @blackboard.add_listener(:other, nil, :after => 'non-existing') { msgs << 'last' }
    @blackboard.add_listener(:other, nil, :after => 'test') { msgs << 'after 1' }
    @blackboard.dispatch_msg(:other)
    assert_equal(['before', 'test', 'after 1', 'after 2', 'last'], msgs)
  end

  def test_remove_listener
    @blackboard.add_listener(:test, 'id') { throw :called }
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }
    @blackboard.remove_listener(:test, 'id')
    @blackboard.dispatch_msg(:test)
  end

  def test_dispatch_msg
    @blackboard.add_listener(:test) { throw :called }
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }
  end

end
