# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tag'

class TestTagTikZ < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::TikZ.new
    Webgen::SourceHandler::Main.new # service create_nodes
    Webgen::SourceHandler::Directory.new # service create_directories
  end

  def call(context, body, path, libs, opts, res, trans, imgattr)
    @obj.set_params({'tag.tikz.path' => path, 'tag.tikz.libraries' => libs,
                      'tag.tikz.opts' => opts, 'tag.tikz.resolution' => res,
                      'tag.tikz.transparent' => trans, 'tag.tikz.img_attr' => imgattr})
    result = @obj.call('tikz', body, context)
    @obj.set_params({})
    result
  end

  def test_call
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, '/file.html', 'file.page')
    context = Webgen::Context.new(:chain => [node])

    output = call(context, '\tikz \draw (0,0) -- (0,1);', 'test.png', [], '', '72 72', false, {})
    assert_equal('<img src="test.png" alt="" />', output)
    assert(root.tree['/test.png'])
    assert_not_nil(root.tree['/test.png'].content)
    root.tree.delete_node('/test.png')

    output = call(context, '\tikz \asdfasdfasf', 'test.png', [], '', '72 72', false, {})
    assert_equal('<img src="test.png" alt="" />', output)
    assert(root.tree['/test.png'])
    assert_raise(Webgen::RenderError) { root.tree['/test.png'].content }
    root.tree.delete_node('/test.png')

    output = call(context, '\tikz \draw (0,0) -- (0,1);', '/images/test.gif', ['arrows'], '->', '72 72', true, {'alt' => 'title'})
    assert_equal('<img src="images/test.gif" alt="title" />', output)
    assert(root.tree['/images/test.gif'])
    assert_not_nil(root.tree['/images/test.gif'].content)
    root.tree.delete_node('/images/test.gif')

    output = call(context, '\tikz \draw (0,0) -- (0,1);', 'images/../img/test.png', [], '', '300 72', true, {})
    assert_equal('<img src="img/test.png" alt="" />', output)
    assert(root.tree['/img/test.png'])
    assert_not_nil(root.tree['/img/test.png'].content)
    root.tree.delete_node('/img/test.png')
  end

  def test_run_command
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    context = Webgen::Context.new(:chain => [root])
    assert_equal("hallo\n", @obj.send(:run_command, echo_cmd('hallo'), context))
    assert_raise(Webgen::RenderError) { @obj.send(:run_command, 'unknown_command 2>&1', context) }
  end

  def echo_cmd(data)
    (RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ?  "echo #{data}" : "echo '#{data}'")
  end


end
