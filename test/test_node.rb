require 'test/unit'
require 'webgen/node'
require 'webgen/tree'

class TestNode < Test::Unit::TestCase

  def setup
    @tree = Webgen::Tree.new
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
      assert_equal({}, node.node_info)
      mi.each {|k,v| assert_equal(v, node[k])}
    end

    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    check_proc.call(node, @tree.dummy_root, 'test/', 'test', 'test.de', '/test.de', 'de', {:test => :value})

    child = Webgen::Node.new(node, 'somename.html', 'somename.page',  {'lang' => 'de'})
    check_proc.call(child, node, 'somename.html', 'somename.page', 'somename.de.page',
                    '/test.de/somename.de.page', 'de', {})

    ['http://webgen.rubyforge.org', 'c:\\test'].each_with_index do |abspath, index|
      cn = 'test' + index.to_s + '.html'
      child = Webgen::Node.new(node, abspath, cn)
      check_proc.call(child, node, abspath, cn, cn, '/test.de/' + cn, nil, {})
    end
  end

  def test_type_checkers
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    child = Webgen::Node.new(node, 'somename.html', 'somename.page', {'lang' => 'de'})
    frag = Webgen::Node.new(child, '#data', '#othertest')
    assert(node.is_directory?)
    assert(child.is_file?)
    assert(frag.is_fragment?)
    assert(node.is_root?)
    assert(!child.is_root?)
  end

  def test_in_lang
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    child_de = Webgen::Node.new(node, 'somename.html', 'somename.page', {'lang' => 'de'})
    child_en = Webgen::Node.new(node, 'somename1.html', 'somename.page', {'lang' => 'en'})
    other = Webgen::Node.new(node, 'other.html', 'other.page', {})
    other_en = Webgen::Node.new(node, 'other1.html', 'other.page', {'lang' => 'en'})

    assert_equal(child_de, child_en.in_lang('de'))
    assert_equal(child_en, child_en.in_lang('en'))
    assert_equal(child_en, child_de.in_lang('en'))
    assert_equal(nil, child_de.in_lang('fr'))
    assert_equal(nil, child_en.in_lang(nil))

    assert_equal(other_en, other.in_lang('en'))
    assert_equal(other, other.in_lang('de'))
    assert_equal(other, other.in_lang(nil))
    assert_equal(other, other_en.in_lang(nil))
    assert_equal(other, other_en.in_lang('de'))
  end

end
