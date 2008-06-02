require 'test/unit'
require 'helper'
require 'webgen/node'
require 'webgen/tree'

class TestNode < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @tree = Webgen::Tree.new
  end

  def create_default_nodes
    {
      :root => node = Webgen::Node.new(@tree.dummy_root, '/', '/'),
      :somename_en => child_en = Webgen::Node.new(node, '/somename.en.html', 'somename.page', {'lang' => 'en'}),
      :somename_de => child_de = Webgen::Node.new(node, '/somename.de.html', 'somename.page', {'lang' => 'de'}),
      :other => Webgen::Node.new(node, '/other.html', 'other.page', {}),
      :other_en => Webgen::Node.new(node, '/other1.html', 'other.page', {'lang' => 'en'}),
      :somename_en_frag => frag_en = Webgen::Node.new(child_en, '/somename.en.html#data', '#othertest'),
      :somename_de_frag => Webgen::Node.new(child_de, '/somename.de.html#data1', '#othertest'),
      :somename_en_fragnest => Webgen::Node.new(frag_en, '/somename.en.html#nested', '#nestedpath'),
      :dir => dir = Webgen::Node.new(node, '/dir/', 'dir/'),
      :dir_file => dir_file = Webgen::Node.new(dir, '/dir/file.html', 'file.html'),
      :dir_file_frag => Webgen::Node.new(dir_file, '/dir/file.html#frag', '#frag'),
      :dir2 => dir2 = Webgen::Node.new(node, '/dir2/', 'dir2/'),
      :dir2_file => Webgen::Node.new(dir2, '/dir2/file.html', 'file.html'),
    }
  end

  def test_initialize
    check_proc = proc do |node, parent, path, cn, lcn, alcn, lang, mi|
      assert_equal(parent, node.parent)
      assert_equal(path, node.path)
      assert_equal(cn, node.cn)
      assert_equal(lcn, node.lcn)
      assert_equal(alcn, node.absolute_lcn)
      assert_equal(lang, node.lang)
      assert(node.dirty)
      assert(node.created)
      assert_equal(mi, node.meta_info)
      assert_equal({:used_nodes => Set.new}, node.node_info)
      mi.each {|k,v| assert_equal(v, node[k])}
    end

    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    check_proc.call(node, @tree.dummy_root, 'test/', 'test', 'test', '/test', nil, {:test => :value})

    child = Webgen::Node.new(node, 'somename.html', 'somename.page',  {'lang' => 'de'})
    check_proc.call(child, node, 'somename.html', 'somename.page', 'somename.de.page',
                    '/test/somename.de.page', 'de', {})

    ['http://webgen.rubyforge.org', 'c:\\test'].each_with_index do |abspath, index|
      cn = 'test' + index.to_s + '.html'
      child = Webgen::Node.new(node, abspath, cn)
      check_proc.call(child, node, abspath, cn, cn, '/test/' + cn, nil, {})
    end
  end

  def test_type_checkers
    nodes = create_default_nodes
    assert(nodes[:root].is_directory?)
    assert(nodes[:somename_en].is_file?)
    assert(nodes[:somename_en_frag].is_fragment?)
    assert(nodes[:root].is_root?)
    assert(!nodes[:somename_en].is_root?)
  end

  def test_meta_info_assignment
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    node[:test] = :newvalue
    node[:other] = :value
    assert_equal(:newvalue, node[:test])
    assert_equal(:value, node[:other])
  end

  def test_in_lang
    nodes = create_default_nodes

    assert_equal(nodes[:somename_de], nodes[:somename_en].in_lang('de'))
    assert_equal(nodes[:somename_en], nodes[:somename_en].in_lang('en'))
    assert_equal(nodes[:somename_en], nodes[:somename_de].in_lang('en'))
    assert_equal(nil, nodes[:somename_de].in_lang('fr'))
    assert_equal(nil, nodes[:somename_en].in_lang(nil))

    assert_equal(nodes[:other_en], nodes[:other].in_lang('en'))
    assert_equal(nodes[:other], nodes[:other].in_lang('de'))
    assert_equal(nodes[:other], nodes[:other].in_lang(nil))
    assert_equal(nodes[:other], nodes[:other_en].in_lang(nil))
    assert_equal(nodes[:other], nodes[:other_en].in_lang('de'))

    assert_equal(nil, nodes[:somename_en_frag].in_lang(nil))
    assert_equal(nodes[:somename_en_frag], nodes[:somename_en_frag].in_lang('en'))
    assert_equal(nodes[:somename_de_frag], nodes[:somename_en_frag].in_lang('de'))
  end

  def test_resolve
    nodes = create_default_nodes

    [nodes[:root], nodes[:somename_de], nodes[:somename_en], nodes[:other]].each do |n|
      assert_equal(nil, n.resolve('somename.page', nil))
      assert_equal(nodes[:somename_en], n.resolve('somename.page', 'en'))
      assert_equal(nodes[:somename_de], n.resolve('somename.page', 'de'))
      assert_equal(nil, n.resolve('somename.page', 'fr'))
      assert_equal(nodes[:somename_en], n.resolve('somename.en.page', nil))
      assert_equal(nodes[:somename_en], n.resolve('somename.en.page', 'en'))
      assert_equal(nodes[:somename_en], n.resolve('somename.en.page', 'de'))
      assert_equal(nil, n.resolve('somename.fr.page', 'de'))

      assert_equal(nodes[:other], n.resolve('other.page', nil))
      assert_equal(nodes[:other], n.resolve('other.page', 'fr'))
      assert_equal(nodes[:other_en], n.resolve('other.page', 'en'))
      assert_equal(nodes[:other_en], n.resolve('other.en.page', nil))
      assert_equal(nodes[:other_en], n.resolve('other.en.page', 'de'))
      assert_equal(nil, n.resolve('other.fr.page', nil))
      assert_equal(nil, n.resolve('other.fr.page', 'en'))
    end

    assert_equal(nodes[:somename_en_frag], nodes[:somename_en].resolve('#othertest', 'de'))
    assert_equal(nodes[:somename_en_frag], nodes[:somename_en].resolve('#othertest', nil))
    assert_equal(nodes[:somename_en_fragnest], nodes[:somename_en].resolve('#nestedpath', nil))

    assert_equal(nil, nodes[:root].resolve('/somename.page#othertest', nil))
    assert_equal(nodes[:somename_en_frag], nodes[:root].resolve('/somename.page#othertest', 'en'))
    assert_equal(nodes[:somename_de_frag], nodes[:root].resolve('/somename.page#othertest', 'de'))
    assert_equal(nodes[:somename_en_frag], nodes[:root].resolve('/somename.en.page#othertest'))
    assert_equal(nodes[:somename_de_frag], nodes[:root].resolve('/somename.de.page#othertest'))
  end

  def test_introspection
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    assert(node.inspect =~ /alcn=\/test/)
  end

  def test_changed
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    node.dirty = node.created = false

    calls = 0
    @website.blackboard.add_listener(:node_changed?) {|n| assert(node, n); node.dirty = true; calls += 1}
    node.changed?
    assert_equal(1, calls)
    node.changed?
    assert_equal(1, calls)

    node.dirty = false
    node.node_info[:used_nodes] << node.absolute_lcn
    node.node_info[:used_nodes] << 'unknown alcn'
    node.node_info[:used_nodes] << @tree.dummy_root.absolute_lcn
    node.changed?
    assert_equal(1, calls)
  end

  def test_method_missing
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    assert_raise(NoMethodError) { node.unknown }
    obj = @website.cache.instance('Object')
    def obj.doit(node); :value; end
    node.node_info[:processor] = 'Object'
    assert_equal(:value, node.doit)
  end

  def test_matching
    root = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    node = Webgen::Node.new(root, 'somepath', 'somefile.html', {'lang' => 'de'})
    assert(node =~ '**/*')
    assert(node =~ '**/somefile.de.HTML')
    assert(node =~ '/test/**/somefile.*.html')
    assert(node !~ '**/*.test')
  end

  def test_absolute_name
    root = Webgen::Node.new(@tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'somepath', 'somefile.html', {'lang' => 'de'})
    assert_equal('/somefile.de.html', node.absolute_lcn)
  end

  def test_route_to
    nodes = create_default_nodes

    #arg is Node
    assert_equal('somename.en.html', nodes[:somename_en].route_to(nodes[:somename_en]))
    assert_equal('somename.de.html', nodes[:somename_en_frag].route_to(nodes[:somename_de]))
    assert_equal('file.html#frag', nodes[:dir].route_to(nodes[:dir_file_frag]))
    assert_equal('#frag', nodes[:dir_file].route_to(nodes[:dir_file_frag]))
    assert_equal('../dir2/file.html', nodes[:dir_file_frag].route_to(nodes[:dir2_file]))
    assert_equal('../dir2/file.html', nodes[:dir_file].route_to(nodes[:dir2_file]))

    assert_equal('./', nodes[:somename_en].route_to(nodes[:root]))
    assert_equal('../', nodes[:dir].route_to(nodes[:root]))
    assert_equal('dir/', nodes[:somename_en].route_to(nodes[:dir]))

    #arg is String
    assert_equal('somename.en.html', nodes[:somename_en].route_to('somename.en.html'))
    assert_equal('../other.html', nodes[:dir_file].route_to('/other.html'))
    assert_equal('../other', nodes[:dir_file].route_to('../other'))
    assert_equal('document/file2', nodes[:dir_file_frag].route_to('document/file2'))
    assert_equal('ftp://test', nodes[:dir].route_to('ftp://test'))

    #test args with '..' and '.': either too many of them or absolute path given
    assert_equal('../dir2', nodes[:dir_file].route_to('../../../dir2/./'))
    assert_equal('../file', nodes[:dir_file].route_to('/dir/../file'))
    assert_equal('file', nodes[:dir_file].route_to('dir/../file'))

    #arg is something else
    assert_raise(ArgumentError) { nodes[:root].route_to(5) }
  end

end
