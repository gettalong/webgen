# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/blackboard'

class TestBlackboard < MiniTest::Unit::TestCase

  def setup
    @blackboard = Webgen::Blackboard.new
  end

  def test_add_listener
    assert_raises(ArgumentError) { @blackboard.add_listener(:test) }
    @blackboard.add_listener([:test, :other]) { throw :called }
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }
    assert_throws(:called) { @blackboard.dispatch_msg(:other) }
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
