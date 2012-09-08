# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tag/relocatable'

class TestTagRelocatable < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_call
    setup_context
    setup_default_nodes(@website.tree)
    @context[:chain] = [@website.tree['/file.en.html']]

    # basic node resolving
    assert_tag_result('dir/subfile.html', 'dir/subfile.html')
    assert_tag_result('', 'german.html')
    assert_tag_result('german.other.html', 'german.de.html')

    # non-existing fragments
    assert_tag_result('', 'file.html#hallo')

    # absolute paths
    assert_tag_result('http://test.com', 'http://test.com')

    # directory paths
    assert_tag_result('dir/', 'dir')
    assert_tag_result('dir2/index.en.html', 'dir2')

    # invalid paths
    @context[:config] = {'tag.relocatable.path' => ':/asdf=-)'}
    Webgen::Tag::Relocatable.call('relocatable', '', @context)
    assert_log_match(/Could not parse path/)
  end

  def assert_tag_result(result, path)
    @context[:config] = {'tag.relocatable.path' => path}
    assert_equal(result, Webgen::Tag::Relocatable.call('relocatable', '', @context))
  end

end
