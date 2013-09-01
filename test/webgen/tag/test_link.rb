# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tag/link'

class TestTagLink < Minitest::Test

  include Webgen::TestHelper

  def test_call
    setup_context
    setup_default_nodes(@website.tree)
    @context[:chain] = [@website.tree['/file.en.html']]
    @context[:config] = {'tag.link.attr' => {}}

    # invalid paths
    @context[:config]['tag.link.path'] = ':/asdf=-)'
    assert_raises(Webgen::RenderError) { Webgen::Tag::Link.call('link', '', @context) }

    # basic node resolving
    assert_tag_result('<a class="help" href="dir2/index.en.html" hreflang="en">index en</a>', 'dir2/index.html')
    @context[:config]['tag.link.attr'] = {'title' => 'other'}
    assert_tag_result('<a class="help" href="dir2/index.en.html" hreflang="en" title="other">index en</a>', 'dir2/index.html')
    @context[:config]['tag.link.attr'] = {}
    assert_tag_result('', 'german.html')

    # non-existing fragments
    assert_tag_result('', 'file.html#hallo')

    # directory paths
    assert_tag_result('<a href="dir/">dir</a>', 'dir')
    assert_tag_result('<a class="help" href="dir2/index.en.html" hreflang="en">routed</a>', 'dir2')
  end

  def assert_tag_result(result, path)
    @context[:config]['tag.link.path'] = path
    assert_equal(result, Webgen::Tag::Link.call('link', '', @context))
  end

end
