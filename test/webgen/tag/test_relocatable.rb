# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tag/relocatable'

class TestTagRelocatable < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def test_call
    setup_context
    @website.logger.verbose = true
    setup_default_nodes(@website.tree)
    @context[:chain] = [@website.tree['/file.en.html']]

    # basic node resolving
    assert_tag_result('dir/subfile.html', 'dir/subfile.html')
    assert_tag_result('dir/subfile.html', 'dir/subfile.html', true)
    assert_tag_result('', 'german.html')
    assert_tag_result('', 'german.html', true)
    assert_tag_result('', 'german.html#other')
    assert_tag_result('', 'german.html#other', true)
    assert_tag_result('german.other.html', 'german.de.html')
    assert_tag_result('german.other.html', 'german.de.html', true)

    # non-existing fragments but existing file
    assert_tag_result('', 'file.html#hallo')
    assert_tag_result('file.en.html#hallo', 'file.html#hallo', true)
    assert_log_match(/Ignoring unknown fragment part/)

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

  def assert_tag_result(result, path, ignore_unknown_fragment = false)
    @context[:config] = {'tag.relocatable.path' => path,
      'tag.relocatable.ignore_unknown_fragment' => ignore_unknown_fragment}
    assert_equal(result, Webgen::Tag::Relocatable.call('relocatable', '', @context))
  end

end
