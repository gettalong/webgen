require 'webgen/test'
require 'webgen/node'

class TreeWalkerTest < Webgen::PluginTestCase

  class TestWalker

    attr_reader :nodes

    def init
      @nodes = []
    end

    def call( node, level )
      @nodes << [node, level]
    end

  end

  plugin_files ['webgen/plugins/miscplugins/treewalker.rb']

  plugin_to_test 'TreeWalkers::TreeWalker'

  def test_execute
    root = Node.new( nil, '/' )
    n1 = Node.new( root, 'n1' )
    n11 = Node.new( n1, 'n11' )
    n111 = Node.new( n11, 'n111' )
    n2 = Node.new( root, 'n2' )
    n12 = Node.new( n1, 'n12' )
    n3 = Node.new( root, 'n3' )
    n31 = Node.new( n3, 'n31' )
    walker = TestWalker.new

    walker.init
    @plugin.execute( root, walker, :forward )
    assert_equal( [[root,0], [n1,1], [n11,2], [n111,3], [n12,2], [n2,1], [n3,1], [n31,2]], walker.nodes )

    walker.init
    @plugin.execute( root, walker, :backward )
    assert_equal( [[n111,3], [n11,2], [n12,2], [n1,1], [n2,1], [n31,2], [n3,1], [root,0]], walker.nodes )
  end

end
