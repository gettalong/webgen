# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/blackboard'

class TestBlackboard < Test::Unit::TestCase

  def setup
    @blackboard = Webgen::Blackboard.new
  end

  def test_add_listener
    assert_raise(ArgumentError) { @blackboard.add_listener(:test, nil) }
    assert_raise(ArgumentError) { @blackboard.add_listener(:test, 'not callable') }
    @blackboard.add_listener([:test, :other], proc { throw :called })
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }
    assert_throws(:called) { @blackboard.dispatch_msg(:other) }
  end

  def test_del_listener
    listener = proc { throw :called }
    @blackboard.add_listener(:test, listener)
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }
    @blackboard.del_listener(:test, listener)
    assert_nothing_thrown { @blackboard.dispatch_msg(:test) }
  end

  def test_dispatch_msg
    listener = proc { throw :called }
    @blackboard.add_listener(:test, listener)
    assert_throws(:called) { @blackboard.dispatch_msg(:test) }
  end

  def test_add_service
    assert_raise(ArgumentError) { @blackboard.add_service(:test, 'not callable') }
    @blackboard.add_service(:test) { throw :called }
    assert_raise(RuntimeError) { @blackboard.add_service(:test, nil) }
  end

  def test_del_service
    @blackboard.add_service(:test) { throw :called }
    assert_throws(:called) { @blackboard.invoke(:test) }
    @blackboard.del_service(:test)
    assert_raise(ArgumentError) { @blackboard.invoke(:test) }
  end

  def service
    yield :test
  end

  def test_invoke
    @blackboard.add_service(:test) { throw :called }
    assert_throws(:called) { @blackboard.invoke(:test) }
    assert_raise(ArgumentError) { @blackboard.invoke(:unknown) }

    @blackboard.add_service(:other, method(:service))
    assert_throws(:test) { @blackboard.invoke(:other) {|p| throw p}}
  end

end
