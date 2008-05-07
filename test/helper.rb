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

  end

end
