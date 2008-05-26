require 'test/unit'
require 'helper'
require 'webgen/sourcehandler/copy'
require 'stringio'

class TestSourceHandlerCopy < Test::Unit::TestCase

  include Test::WebsiteHelper

  class TestCP
    def call(context); context.content = context.content.reverse; end
  end

  def setup
    super
    @website.config['contentprocessor.map']['test'] = 'TestSourceHandlerCopy::TestCP'
    @obj = Webgen::SourceHandler::Copy.new
    @root = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'test/', 'test')
    @without = @obj.create_node(@root, path_with_meta_info('/default.css') {StringIO.new('# header')})
    @with = @obj.create_node(@root, path_with_meta_info('/other.test.css') {StringIO.new('# header')})
  end

  def test_create_node
    assert_not_nil(@without)
    assert_equal(nil, @without.node_info[:preprocessor])
    assert_equal('test/default.css', @without.path)

    assert_not_nil(@with)
    assert_equal('test', @with.node_info[:preprocessor])
    assert_equal('test/other.css', @with.path)

    node = @obj.create_node(@root, path_with_meta_info('/other.unknown.css') {StringIO.new('# header')})
    assert_equal(nil, node.node_info[:preprocessor])
  end

  def test_content
    @website.blackboard.add_service(:source_paths) do
      {'/default.css' => path_with_meta_info('/default.css') {StringIO.new('# header')}}
    end
    @without.node_info[:src] = @with.node_info[:src] = '/default.css'
    assert_kind_of(Webgen::Path::SourceIO, @without.content)
    assert_equal('# header'.reverse, @with.content)
  end

end
