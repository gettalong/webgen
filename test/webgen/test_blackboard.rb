# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/blackboard'

class TestBlackboard < MiniTest::Unit::TestCase

  def setup
    @blackboard = Webgen::Blackboard.new
  end

  def test_add_listener
    assert_raises(ArgumentError) { @blackboard.add_listener(:test, nil) }
    assert_raises(ArgumentError) { @blackboard.add_listener(:test, 'not callable') }
    @blackboard.add_listener([:test, :other], proc { throw :called })
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }
    assert_throws(:called) { @blackboard.dispatch_msg(:other) }
  end

  def test_remove_listener
    listener = proc { throw :called }
    @blackboard.add_listener(:test, listener)
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }
    @blackboard.remove_listener(:test, listener)
    @blackboard.dispatch_msg(:test)
  end

  def test_dispatch_msg
    listener = proc { throw :called }
    @blackboard.add_listener(:test, listener)
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }
  end

end
