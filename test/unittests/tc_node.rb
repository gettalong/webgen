require 'webgen/test'
require 'webgen/node'
require 'yaml'


class TestProcessor

  def return( node, str )
    str + ' ' + node.path
  end

  def with_block( node, str )
    yield( node, str )
  end

end

class NodeTest < Webgen::TestCase

  def setup
    @ni = YAML::load( File.read( fixture_path( 'nodes.yaml' ) ) )
    @n = {}
    @ni.each do |info|
      @n[info['ref'] || info['url']] = Node.new( @n[info['parent']], info['url'] )
      @n[info['ref'] || info['url']].meta_info.update( info['meta_info'] ) if info['meta_info']
      @n[info['ref'] || info['url']].node_info.update( info['node_info'] ) if info['node_info']
    end
  end


  def test_root
    assert_equal( @n['/'], Node.root( @n['file_aa'] ) )
  end

  def test_inspect
    assert_kind_of( String, @n['file_aa'].inspect )
  end

  def test_parent
    x = Node.new( nil, 'test' )
    assert( @n['/'].include?( @n['dir_a/'] ) )
    @n['dir_a/'].parent = x
    assert( @n['dir_a/'].parent == x )
    assert( x.include?( @n['dir_a/'] ) )
    assert( !@n['/'].include?( @n['dir_a/'] ) )
  end

  def test_accessors
    assert_equal( nil, @n['/'].parent )
    assert_equal( '../out/../dir1/', @n['/'].path )


    assert_equal( @n['dir_a/'], @n['file_aa'].parent )

    assert_equal( {'title'=>'file_a'}, @n['file_a'].meta_info )
    assert_equal( {}, @n['file_a'].node_info )

    assert_equal( 'test', @n['/']['test'] )
    @n['/']['test'] = 'notest'
    assert_equal( 'notest', @n['/']['test'] )
    assert_equal( @n['/'].meta_info['test'], @n['/']['test'] )

    assert( @n['/'].is_directory? )
    assert( @n['dir_a/'].is_directory? )
    assert( @n['file_aa'].is_file? )
    assert( @n['file_aa#'].is_fragment? )
  end

  def test_level
    assert_equal( 0, @n['/'].level )
    assert_equal( 1, @n['dir_a/'].level )
    assert_equal( 2, @n['file_aa'].level )
  end

  def test_full_path
    assert_equal( '../out/../dir1/', @n['/'].full_path )
    assert_equal( '../out/../dir1/dir_a/file_aa', @n['file_aa'].full_path )
    assert_equal( 'http://localhost/file_ah#doit', @n['file_ah#'].full_path )
  end

  def test_absolute_path
    assert_equal( '/', @n['/'].absolute_path )
    assert_equal( '/dir_a/file_aa', @n['file_aa'].absolute_path )
    assert_equal( 'http://localhost/file_ah#doit', @n['file_ah#'].absolute_path )

    root = Node.new( nil, 'C:/webgen/output/')
    assert_equal( '/', root.absolute_path )
  end

  def test_route_to
    #arg is Node
    assert_equal( 'file_a', @n['file_a'].route_to( @n['file_a'] ) )
    assert_equal( 'file_aa', @n['file_aa#'].route_to( @n['file_aa'] ) )
    assert_equal( 'file_aa#doit', @n['dir_a/'].route_to( @n['file_aa#'] ) )
    assert_equal( '#doit', @n['file_aa'].route_to( @n['file_aa#'] ) )
    assert_equal( '../dir_b/file_ba', @n['file_aa#'].route_to( @n['file_ba'] ) )
    assert_equal( '../dir_b/file_bb', @n['file_aa'].route_to( @n['file_bb'] ) )
    assert_equal( 'http://localhost/file_ah', @n['dir_a/'].route_to( @n['file_ah'] ) )

    assert_equal( './', @n['file_a'].route_to( @n['/'] ) )
    assert_equal( '../', @n['dir_a/'].route_to( @n['/'] ) )
    assert_equal( 'dir_a/', @n['file_a'].route_to( @n['dir_a/'] ) )

    #arg is String
    assert_equal( 'file_a', @n['file_a'].route_to( 'file_a' ) )
    assert_equal( '../other', @n['file_aa'].route_to( '/other' ) )
    assert_equal( '../other', @n['file_aa'].route_to( '../other' ) )
    assert_equal( 'document/file2', @n['file_aa#'].route_to( 'document/file2' ) )
    assert_equal( 'ftp://test', @n['dir_a/'].route_to( 'ftp://test' ) )

    assert_equal( './', @n['file_a'].route_to( '/' ) )
    assert_equal( './', @n['dir_a/'].route_to( '/dir_a' ) )

    assert_equal( '../other', @n['file_aa'].route_to( '/other' ) )

    #test args with '..' and '.': either too many of them or absolute path given
    assert_equal( '../dir', @n['file_aa'].route_to( '../../../dir/./' ) )
    assert_equal( '../dir', @n['file_aa'].route_to( '/../../../dir/./' ) )
    assert_equal( '../file', @n['file_aa'].route_to( '/dir/../file' ) )
    assert_equal( 'file', @n['file_aa'].route_to( 'dir/../file' ) )

    #arg is something else
    assert_raise( ArgumentError ) { @n['file_a'].route_to( 5 ) }
  end

  def test_in_subtree_of
    assert( @n['file_a'].in_subtree_of?( @n['/'] ) )
    assert( @n['dir_a/'].in_subtree_of?( @n['/'] ) )

    assert( @n['file_aa'].in_subtree_of?( @n['dir_a/'] ) )

    assert( @n['file_aa#'].in_subtree_of?( @n['/'] ) )
    assert( @n['file_aa#'].in_subtree_of?( @n['dir_a/'] ) )
    assert( @n['file_aa#'].in_subtree_of?( @n['file_aa'] ) )

    assert( @n['file_ah#'].in_subtree_of?( @n['file_ah'] ) )
    assert( @n['file_ah#'].in_subtree_of?( @n['/'] ) )

    assert( !@n['file_ba'].in_subtree_of?( @n['dir_a/'] ) )
    assert( !@n['file_a'].in_subtree_of?( @n['dir_a/'] ) )
    assert( !@n['file_a'].in_subtree_of?( @n['file_aa'] ) )
    assert( !@n['file_aa'].in_subtree_of?( @n['file_ab'] ) )
  end

  def test_resolve_node
    assert_equal( @n['file_aa#'], @n['file_aa#'].resolve_node( '' ) )
    assert_equal( @n['file_aa#'], @n['file_aa#'].resolve_node( 'file_aa#doit' ) )
    assert_equal( @n['file_aa#'], @n['file_aa#'].resolve_node( '#doit' ) )
    assert_equal( @n['file_aa#2'], @n['file_aa#'].resolve_node( '#doelse' ) )
    assert_equal( @n['file_aa'], @n['file_aa#'].resolve_node( 'file_aa' ) )
    assert_equal( @n['dir_a/'], @n['file_aa#'].resolve_node( '../dir_a/' ) )
    assert_equal( @n['dir_a/'], @n['file_aa#'].resolve_node( '../dir_a' ) )
    assert_equal( @n['/'], @n['file_aa#'].resolve_node( '..' ) )
    assert_equal( @n['file_ba'], @n['file_aa'].resolve_node( '../dir_b/file_ba' ) )
    assert_equal( @n['file_ba#'], @n['file_aa'].resolve_node( '../dir_b/file_ba#doit' ) )
    assert_equal( @n['file_zb'], @n['file_aa'].resolve_node( '../dir_z/file_zb' ) )

    assert_equal( @n['file_aa#2'], @n['file_ba'].resolve_node( '/dir_a/file_aa#doelse' ) )
    assert_equal( @n['file_zb'], @n['file_aa'].resolve_node( '/dir_z/file_zb' ) )

    assert_nil( @n['file_aa'].resolve_node( '../dir_b/file_bb' ) )
    assert_nil( @n['dir_a/'].resolve_node( 'invalid_file' ) )
    assert_nil( @n['file_a'].resolve_node( '../invalid' ) )

    assert_raise( ArgumentError ) { @n['file_aa'].resolve_node( 5456 ) }

    assert_equal( @n['file_aa#'], @n['file_aa#'].resolve_node( 'file_aa?tst#doit' ) )
    assert_equal( nil, @n['file_aa#'].resolve_node( 'file_aa#doit?tst' ) )
    assert_equal( nil, @n['file_aa#'].resolve_node( 'file_aa#doit_invalid' ) )
  end

  def test_processor_routing
    assert_raise( NoMethodError ) { @n['/'].return( 'hello' ) }
    @n['/'].node_info[:processor] = TestProcessor.new
    assert_equal( 'hello ../out/../dir1/', @n['/'].return( 'hello' ) )
    assert_throws( :found ) { @n['/'].with_block( 'hello' ) {|n,s| assert_equal( 'hello', s ); throw :found } }
  end

  def test_match_operator
    assert_equal( 'dir_a/', @n['dir_a/'] =~ 'dir_a/' )
    assert_equal( 'dir_a', @n['dir_a/'] =~ 'dir_a' )
    assert_equal( 'dir_a/', @n['dir_a/'] =~ 'dir_a/something_else' )
    assert( !( @n['dir_a/'] =~ 'dir_anot' ) )
    assert( !( @n['dir_a/'] =~ 'not/dir_a' ) )

    assert_equal( 'file_aa', @n['file_aa'] =~ 'file_aa' )
    assert_equal( 'file_aa', @n['file_aa'] =~ 'file_aa#doit' )
    assert( !( @n['file_aa'] =~ 'file_aab' ) )
    assert( !( @n['file_aa'] =~ 'not_file_aab' ) )

    assert_equal( '#doit', @n['file_aa#'] =~ '#doit' )
    assert( !( @n['file_aa#'] =~ '#doit?sdf' ) )
    assert( !( @n['file_aa#'] =~ 'dfs#doit' ) )
  end

  def test_order_info
    assert_equal( 0, @n['file_a'].order_info )
    assert_equal( 0, @n['file_b'].order_info )
    assert_equal( [@n['file_a'], @n['file_b']], [@n['file_b'], @n['file_a']].sort )
    assert_equal( 1, @n['file_ab'].order_info )
    assert_equal( 2, @n['file_aa'].order_info )
    assert_equal( [@n['file_ab'], @n['file_aa']], [@n['file_aa'], @n['file_ab']].sort )
  end

end
