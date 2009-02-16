# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/websiteaccess'


class TestWebsiteaccess < Test::Unit::TestCase

  class WSAccessSubClass
    include Webgen::WebsiteAccess

    def get_private_website
      website
    end
  end

  def test_accessors
    Thread.current[:webgen_website] = :value
    assert_equal(:value, Webgen::WebsiteAccess.website)
    assert_equal(:value, WSAccessSubClass.website)
    assert_equal(:value, WSAccessSubClass.new.get_private_website)
    Thread.current[:webgen_website] = nil
  end

end
