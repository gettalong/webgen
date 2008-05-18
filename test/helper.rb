require 'webgen/blackboard'
require 'webgen/website'

module Test

  module WebsiteHelper

    def setup
      super
      @website = Webgen::Website.new
      @website.init
      Thread.current[:webgen_website] = @website
    end

    def teardown
      Thread.current[:webgen_website] = nil
    end

    def path_with_meta_info(path, mi = {}, &block)
      path = Webgen::Path.new(path, &block)
      path.meta_info.update(@website.config['sourcehandler.default_meta_info'][:all].merge(mi))
      path
    end

  end

end
