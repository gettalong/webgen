require 'test/unit'
require 'webgen/website'

class WebSiteTest < Test::Unit::TestCase

  def test_website_template
    t = Webgen::WebSiteTemplate.entries
    assert( t.size >= 1 )
    assert_kind_of( Hash, t )
    assert_kind_of( Webgen::WebSiteTemplate, t['default'] )
    t.each {|name, template| check_dir_info( name, template )}
  end

  def test_website_styles
    t = Webgen::WebSiteStyle.entries
    assert( t.size >= 1 )
    assert_kind_of( Hash, t )
    assert_kind_of( Webgen::WebSiteStyle, t['default'] )
    t.each {|name, style| check_dir_info( name, style )}
    assert_equal( 2, t['default'].files.length )
  end

  #######
  private
  #######

  def check_dir_info( name, dir_info )
    assert_kind_of( Webgen::DirectoryInfo, dir_info )
    assert_equal( name, dir_info.name )
    assert_kind_of( String, dir_info.infos['description'] )
    assert_kind_of( String, dir_info.infos['creator'] )
    assert_kind_of( Hash, dir_info.infos )
    assert_kind_of( Array, dir_info.files )
  end

end
