# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'logger'
require 'stringio'
require 'webgen/node_finder'
require 'webgen/tree'

class TestNodeFinder < MiniTest::Unit::TestCase

  def setup
    @nf = Webgen::NodeFinder.new
    @config = {}
    website = MiniTest::Mock.new
    website.expect(:config, @config)
    @nf.website = website
  end

  def test_add_filter_module
    m = Module.new
    m.send(:define_method, :filter_something) { :value }

    assert_raises(ArgumentError) { @nf.add_filter_module(m, :name => 'unknown_method') }
    assert_raises(NoMethodError) { @nf.filter_something }
    @nf.add_filter_module(m, :something => 'filter_something')
    assert_equal('filter_something', @nf.instance_eval { @mapping[:something] })
    assert_equal(:value, @nf.filter_something)
  end

  def test_find
    tree = Webgen::Tree.new(@nf.website)
    @nf.website.expect(:tree, tree)
    @nf.website.expect(:logger, ::Logger.new(StringIO.new))
    blackboard = MiniTest::Mock.new
    blackboard.expect(:dispatch_msg, nil, [nil, nil, nil])
    @nf.website.expect(:blackboard, blackboard)

    nodes = {
      :root => root = Webgen::Node.new(tree.dummy_root, '/', '/'),
      :somename_en => child_en = Webgen::Node.new(root, 'somename.html', '/somename.en.html', {'lang' => 'en', 'title' => 'somename en', 'sort_info' => 3}),
      :somename_de => child_de = Webgen::Node.new(root, 'somename.html', '/somename.de.html', {'lang' => 'de', 'title' => 'somename de', 'sort_info' => 5}),
      :other => Webgen::Node.new(root, 'other.html', '/other.html', {'title' => 'other'}),
      :other_en => Webgen::Node.new(root, 'other.html', '/other1.html', {'lang' => 'en', 'title' => 'other en'}),
      :somename_en_frag => frag_en = Webgen::Node.new(child_en, '#othertest', '/somename.en.html#frag', {'title' => 'frag'}),
      :somename_en_fragnest => Webgen::Node.new(frag_en, '#nestedpath', '/somename.en.html#fragnest/', {'title' => 'fragnest'}),
      :dir => dir = Webgen::Node.new(root, 'dir/', '/dir/', {'title' => 'dir'}),
      :dir_file => dir_file = Webgen::Node.new(dir, 'file.html', '/dir/file.html', {'title' => 'file'}),
      :dir_file_frag => Webgen::Node.new(dir_file, '#frag', '/dir/file.html#frag', {'title' => 'frag'}),
      :dir_dir => dir_dir = Webgen::Node.new(dir, 'subdir/' , '/dir/subdir/', {'title' => 'dir'}),
      :dir_dir_file => Webgen::Node.new(dir_dir, 'file.html', '/dir/subdir/file.html', {'title' => 'file1'}),
      :dir2 => dir2 = Webgen::Node.new(root, 'dir2/', '/dir2/', {'proxy_path' => 'index.html', 'title' => 'dir2'}),
      :dir2_index_en => Webgen::Node.new(dir2, 'index.html', '/dir2/index.html',
                                         {'lang' => 'en', 'routed_title' => 'routed', 'title' => 'index en'}),
      :dir2_index_de => Webgen::Node.new(dir2, 'index.html', '/dir2/index.de.html',
                                         {'lang' => 'de', 'routed_title' => 'routed_de', 'title' => 'index de'}),
    }

    check = lambda do |correct, result|
      assert_equal(correct.collect {|n| nodes[n] }, result, "Failure at #{caller[0]}")
    end

    assert_raises(ArgumentError) { @nf.find({:alcn => '/'}, nodes[:root]) }

    # test using configured search options
    @config['node_finder.option_sets'] = {'simple' => {:alcn => '', :unknown => '', :name => 'simple'}}
    check.call([:root], @nf.find('simple', nodes[:root]))
    check.call([:somename_en], @nf.find('simple', nodes[:somename_en]))

    # test limit, offset, flatten
    check.call([:somename_en, :other_en],
               @nf.find({:alcn => '/**/*.en.html', :limit => 2, :name => 'test'}, nodes[:root]))
    check.call([:dir2_index_en],
               @nf.find({:alcn => '/**/*.en.html', :limit => 2, :offset => 2, :name => 'test'}, nodes[:root]))

    assert_equal([[nodes[:somename_en], [nodes[:somename_en_frag]]], nodes[:somename_de],
                  nodes[:other], nodes[:other_en],
                  [nodes[:dir], [nodes[:dir_file], nodes[:dir_dir]]],
                  [nodes[:dir2], [nodes[:dir2_index_en], nodes[:dir2_index_de]]]
                 ],
                 @nf.find({:levels => [1,2], :name => 'test'}, nodes[:root]))

    # test sort methods
    check.call([:somename_en, :somename_de, :dir_file, :dir_dir_file, :dir2_index_de,
                :dir2_index_en, :other, :other_en],
               @nf.find({:alcn => '/**/*.html', :name => 'test', :flatten => true, :sort => true}, nodes[:root]))
    check.call([:dir_file, :dir_dir_file, :dir2_index_de, :dir2_index_en, :other, :other_en,
                :somename_de, :somename_en],
               @nf.find({:alcn => '/**/*.html', :name => 'test', :flatten => true, :sort => 'title'}, nodes[:root]))
    assert_equal([[nodes[:somename_en], [nodes[:somename_en_frag]]], nodes[:somename_de],
                  [nodes[:dir], [nodes[:dir_dir], nodes[:dir_file]]],
                  [nodes[:dir2], [nodes[:dir2_index_de], nodes[:dir2_index_en]]],
                  nodes[:other], nodes[:other_en],
                 ],
                 @nf.find({:levels => [1,2], :name => 'test', :sort => true}, nodes[:root]))

    # test filter: meta info keys/values
    check.call([:somename_en_frag, :dir_file_frag],
               @nf.find({'title' => 'frag', :name => 'test', :flatten => true}, nodes[:root]))

    # test filter: alcn
    check.call([:root],
               @nf.find({:alcn => '/', :name => 'test'}, nodes[:root]))
    check.call([:somename_en, :somename_de, :other, :other_en, :dir_file, :dir_dir_file,
                :dir2_index_en, :dir2_index_de],
               @nf.find({:alcn => '/**/*.html', :name => 'test', :flatten => true}, nodes[:root]))
    check.call([:root, :dir_file, :dir_file_frag, :dir_dir],
               @nf.find({:alcn => ['/', '*'], :name => 'test', :flatten => true}, nodes[:dir]))

    # test filter: and/or
    check.call([:somename_en, :somename_de, :other, :other_en],
               @nf.find({:alcn => '/**/*.html', :and => {:alcn => '*.html'},
                        :name => 'test', :flatten => true}, nodes[:root]))
    check.call([:somename_en, :somename_de, :other, :other_en, :dir_file, :dir_dir_file,
                :dir2_index_en, :dir2_index_de, :root],
               @nf.find({:alcn => '/**/*.html', :or => 'simple', :name => 'test', :flatten => true}, nodes[:root]))

    # test filter: levels
    check.call([:root],
               @nf.find({:levels => [0, 0], :name => 'test', :flatten => true}, nodes[:dir]))
    check.call([:somename_en_fragnest, :dir_file_frag, :dir_dir_file],
               @nf.find({:levels => [3,3], :name => 'test', :flatten => true}, nodes[:dir]))
    check.call([:root, :somename_en, :somename_de, :other, :other_en, :dir, :dir2],
               @nf.find({:levels => [0,1], :name => 'test', :flatten => true}, nodes[:dir]))

    # test filter: langs
    check.call([:somename_en, :other_en, :dir2_index_en],
               @nf.find({:lang => 'en', :name => 'test', :flatten => true}, nodes[:dir]))
    check.call([:somename_en, :somename_de, :other_en, :dir2_index_en, :dir2_index_de],
               @nf.find({:lang => ['en', 'de'], :name => 'test', :flatten => true}, nodes[:dir]))
    check.call([:somename_en, :other_en, :dir2_index_en],
               @nf.find({:lang => :node, :name => 'test', :flatten => true}, nodes[:somename_en]))

    @nf.website.verify
  end

end
