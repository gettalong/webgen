# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'ostruct'
require 'webgen/error'
require 'webgen/context'
require 'webgen/node'
require 'webgen/path_handler/page_utils'

module Test

  module WebgenAssertions

    def assert_error_on_line(error_class, line)
      begin
        yield
      rescue error_class => e
        assert_equal(line, (e.respond_to?(:line) ? e.line : Webgen::Error.error_line(e)))
      else
        fail "No exception raised though #{error_class} expected"
      end
    end

  end

  def self.setup_content_processor_test
    website = MiniTest::Mock.new
    website.expect(:ext, OpenStruct.new)
    node = MiniTest::Mock.new
    node.expect(:alcn, '/test')
    context = Webgen::Context.new(website, :chain => [node], :doit => 'hallo')
    [website, node, context]
  end

  def self.setup_tag_test
    website = MiniTest::Mock.new
    website.expect(:ext, OpenStruct.new)
    context = Webgen::Context.new(website)
    [website, context]
  end

  class RenderNode < Webgen::Node

    include Webgen::PathHandler::PageUtils

    def blocks
      node_info[:blocks]
    end

    def render_block(name, context)
      super(self, name, context)
    end

    def template_chain
      [self]
    end

  end

  def self.setup_tag_template(root)
    template = RenderNode.new(root, 'tag.template', '/tag.template')
    template_data = File.read(File.join(Webgen.data_dir, 'passive_sources', 'templates', 'tag.template'))
    page = Webgen::Page.from_data(template_data)
    template.node_info[:blocks] = page.blocks
    template.meta_info.update(page.meta_info)
    template
  end

  def self.create_default_nodes(tree)
    {
      :root => root = Webgen::Node.new(tree.dummy_root, '/', '/'),
      :somename_en => child_en = Webgen::Node.new(root, 'somename.html', '/somename.en.html', {'lang' => 'en', 'title' => 'somename en'}),
      :somename_de => child_de = Webgen::Node.new(root, 'somename.html', '/somename.de.html', {'lang' => 'de', 'title' => 'somename de'}),
      :other => Webgen::Node.new(root, 'other.html', '/other.html', {'title' => 'other'}),
      :other_en => Webgen::Node.new(root, 'other.html', '/other1.html', {'lang' => 'en', 'title' => 'other en'}),
      :somename_en_frag => frag_en = Webgen::Node.new(child_en, '#othertest', '/somename.en.html#frag', {'title' => 'frag'}),
      :somename_de_frag => Webgen::Node.new(child_de, '#othertest', '/somename.de.html#frag', {'title' => 'frag'}),
      :somename_en_fragnest => Webgen::Node.new(frag_en, '#nestedpath', '/somename.en.html#fragnest/', {'title' => 'fragnest'}),
      :dir => dir = Webgen::Node.new(root, 'dir/', '/dir/', {'title' => 'dir'}),
      :dir_file => dir_file = Webgen::Node.new(dir, 'file.html', '/dir/file.html', {'title' => 'file'}),
      :dir_file_frag => Webgen::Node.new(dir_file, '#frag', '/dir/file.html#frag', {'title' => 'frag'}),
      :dir2 => dir2 = Webgen::Node.new(root, 'dir2/', '/dir2/', {'proxy_path' => 'index.html', 'title' => 'dir2'}),
      :dir2_index_en => Webgen::Node.new(dir2, 'index.html', '/dir2/index.html',
                                         {'lang' => 'en', 'routed_title' => 'routed', 'title' => 'index en',
                                           'link_attrs' => {'class'=>'help'}}),
      :dir2_index_de => Webgen::Node.new(dir2, 'index.html', '/dir2/index.de.html',
                                         {'lang' => 'de', 'routed_title' => 'routed_de', 'title' => 'index de'}),
    }
  end


=begin
require 'webgen/blackboard'
require 'webgen/website'

  module WebsiteHelper

    include WebgenAssertions

    def setup
      super
      @website = Webgen::Website.new('test', nil) {|cfg| cfg['passive_sources'] = []}
      @website.init
      Thread.current[:webgen_website] = @website
    end

    def teardown
      Thread.current[:webgen_website] = nil
    end

    def path_with_meta_info(path, mi = {}, sh = nil, &block)
      path = Webgen::Path.new(path, &block)
      path.meta_info.update(@website.config['sourcehandler.default_meta_info'][:all].merge(mi))
      path.meta_info.update((@website.config['sourcehandler.default_meta_info'][sh] || {}).merge(mi)) if sh
      path
    end

    def create_sitemap_nodes
      {
        :root => root = Webgen::Node.new(@website.tree.dummy_root, '/', '/', {'index_path' => 'index.html'}),
        :dir1 => dir1 = Webgen::Node.new(root, '/dir1/', 'dir1/'),
        :file11_en => file11 = Webgen::Node.new(dir1, '/dir1/file11.en.html', 'file11.html', {'lang' => 'en', 'in_menu' => true, 'kind' => 'page'}),
        :file11_en_f1 => file11_f1 = Webgen::Node.new(file11, '/dir1/file11.en.html#f1', '#f1', {'in_menu' => true}),
        :dir2 => dir2 = Webgen::Node.new(root, '/dir2/', 'dir2/', {'kind' => 'directory'}),
        :file21_en => Webgen::Node.new(dir2, '/dir2/file21.en.html', 'file21.html', {'lang' => 'en', 'in_menu' => false, 'kind' => 'other'}),
        :file1_de => Webgen::Node.new(root, '/file1.de.html', 'file1.html', {'lang' => 'de', 'in_menu' => true, 'kind' => 'page'}),
        :index_en => Webgen::Node.new(root, '/index.en.html', 'index.html', {'lang' => 'en', 'kind' => 'page'}),
        :dir3 => dir3 = Webgen::Node.new(root, '/dir3/', 'dir3/', {'kind' => 'directory', 'index_path' => 'index.html'}),
        :index3_en => Webgen::Node.new(dir3, '/dir3/index.en.html', 'index.html', {'lang' => 'en', 'kind' => 'page'})
      }
    end

  end
=end

end
