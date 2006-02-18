require 'webgen/test'
require 'webgen/composite'


class CompositeTest < Webgen::TestCase

  class CompositeTestclass
    include Composite
  end


  def setup
    @testclass = CompositeTestclass.new
    @children = ['hello', 'beta', 'gamma']
  end


  def test_initialize
    assert_kind_of( Composite, @testclass )
    assert_not_nil( @testclass.children )
    assert_equal( 0, @testclass.children.length )
  end


  def test_add_children
    assert_nothing_raised do
      @testclass.add_children @children
    end
    assert_equal( @children, @testclass.children )
    assert_raise( ArgumentError ) do
      @testclass.add_children 'test'
    end
  end


  def test_del_children
    assert_nothing_raised do @testclass.del_children end
    @testclass.add_children @children
    assert_equal( @children, @testclass.children )
    @testclass.del_children
    assert_equal( 0, @testclass.children.length )
  end


  def test_add_child
    child = "hello"
    assert_nothing_raised do
      @testclass.add_child child
      assert_equal( 1, @testclass.children.length )
      assert_equal( child, @testclass.children[0] )

      @testclass.add_child child
      assert_equal( 1, @testclass.children.length )
    end
  end


  def test_del_child
    assert_nothing_raised do
      @testclass.add_children @children
      @testclass.del_child 'beta'
      assert_equal( ['hello', 'gamma'], @testclass.children )
      @testclass.del_child 1
      assert_equal( ['hello'], @testclass.children )
    end
  end


  def test_has_children
    assert_nothing_raised do
      assert( !@testclass.has_children? )
      @testclass.add_children @children
      assert( @testclass.has_children? )
    end
  end

end
