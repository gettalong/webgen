require 'webgen/blackboard'
require 'webgen/website'

module Test

  module WebsiteHelper

    def setup
      super
      @website = Webgen::Website.new('test', nil)
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
        :root => root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/', {'index_path' => 'index.html'}),
        :dir1 => dir1 = Webgen::Node.new(root, '/dir1/', 'dir1/'),
        :file11_en => file11 = Webgen::Node.new(dir1, '/dir1/file11.en.html', 'file11.html', {'lang' => 'en', 'in_menu' => true, 'kind' => 'page'}),
        :file11_en_f1 => file11_f1 = Webgen::Node.new(file11, '/dir1/file11.en.html#f1', '#f1', {'in_menu' => true}),
        :dir2 => dir2 = Webgen::Node.new(root, '/dir2/', 'dir2/', {'kind' => 'directory'}),
        :file21_en => Webgen::Node.new(dir2, '/dir2/file21.en.html', 'file21.html', {'lang' => 'en', 'in_menu' => false, 'kind' => 'other'}),
        :file1_de => Webgen::Node.new(root, '/file1.de.html', 'file1.html', {'lang' => 'de', 'in_menu' => true, 'kind' => 'page'}),
        :index_en => Webgen::Node.new(root, '/index.en.html', 'index.html', {'lang' => 'en', 'kind' => 'page'}),
      }
    end

  end

end
