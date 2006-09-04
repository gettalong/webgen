require 'webgen/test'

class GalleryInfoTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/gallery.rb',
  ]

  def setup
    super
    iclass = FileHandlers::GalleryFileHandler::GalleryInfo::Image
    gclass = FileHandlers::GalleryFileHandler::GalleryInfo::Gallery
    @galleries = []
    @galleries << gclass.new( 'gal1.html', {},
                              [iclass.new( 'test1.html', {'thumbnail' => 'tn_test1.jpg'}, 'test1.jpg' ), iclass.new( 'test2.html', {'thumbnailSize' => '100x50'}, 'test2.jpg' )] )
    @galleries << gclass.new( 'gal2.html', {},
                              [iclass.new( 'test3.html', {}, 'test3.jpg' ), iclass.new( 'test4.html', {}, 'test4.jpg' )] )
    @galleries << gclass.new( 'gal3.html', {},
                              [iclass.new( 'test5.html', {}, 'test5.jpg' ), iclass.new( 'test6.html', {}, 'test6.jpg' )] )
  end

  def test_cur_image
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0, 0 )
    assert_equal( @galleries[0].images[0], ginfo.cur_image )
  end

  def test_cur_gallery
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0 )
    assert_equal( @galleries[0], ginfo.cur_gallery )
  end

  def test_prev_image
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0, 0 )
    assert_equal( nil, ginfo.prev_image )
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0, 1 )
    assert_equal( @galleries[0].images[0], ginfo.prev_image )
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 1, 0 )
    assert_equal( @galleries[0].images[1], ginfo.prev_image )
  end

  def test_next_image
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 2, 1 )
    assert_equal( nil, ginfo.next_image )
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0, 0 )
    assert_equal( @galleries[0].images[1], ginfo.next_image )
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0, 1 )
    assert_equal( @galleries[1].images[0], ginfo.next_image )
  end

  def test_prev_gallery
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0 )
    assert_equal( nil, ginfo.prev_gallery )
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 1 )
    assert_equal( @galleries[0], ginfo.prev_gallery )
  end

  def test_next_gallery
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 2 )
    assert_equal( nil, ginfo.next_gallery )
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0 )
    assert_equal( @galleries[1], ginfo.next_gallery )
  end

  def test_image_accessors
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0, 0 )
    assert_equal( '<img src="{relocatable: tn_test1.jpg}" alt="" />', ginfo.cur_image.thumbnail )
    assert_equal( '<img src="{relocatable: test2.jpg}" width="100" height="50" alt="" />', ginfo.next_image.thumbnail )
  end

  def test_gallery_accessors
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0, 0 )
    assert_equal( '<img src="{relocatable: tn_test1.jpg}" alt="" />', ginfo.cur_gallery.thumbnail )
    assert_equal( '<img src="{relocatable: test3.jpg}" width="" height="" alt="" />', ginfo.next_gallery.thumbnail )
  end

end

class GalleryFileHandlerTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/gallery.rb'
  ]
  plugin_to_test 'FileHandlers::GalleryFileHandler'

  def test_param
    assert_nothing_raised { @plugin.instance_eval { param('imagesPerPage') } }
  end

  def test_create_node
    root = Node.new( nil, '/' )
    root.node_info[:src] = ''

    # with a main page
    assert_nil( @plugin.create_node( fixture_path( 'test.gallery' ), root, {} ) )
    assert_not_nil( root.resolve_node( 'Test.page' ) )
    assert_not_nil( root.resolve_node( 'Test_1.page' ) )
    assert_not_nil( root.resolve_node( 'Test_2.page' ) )
    assert_not_nil( root.resolve_node( 'Test_test1_jpg.page' ) )
    assert_not_nil( root.resolve_node( 'Test_test2_jpg.page' ) )
    assert_not_nil( root.resolve_node( 'Test_test3_jpg.page' ) )
    assert_not_nil( root.resolve_node( 'Test_test4_jpg.page' ) )

    node = root.resolve_node( 'Test_test3_jpg.page' )
    assert_kind_of( FileHandlers::GalleryFileHandler::GalleryInfo, node.node_info[:ginfo] )
    assert_equal( 'test3.jpg', node.node_info[:ginfo].cur_image.filename )
    assert_equal( node.path, node.node_info[:ginfo].cur_image.pagename )
    assert_equal( 'gallery_image.template', node['template'] )

    node = root.resolve_node( 'Test_2.page' )
    assert_kind_of( FileHandlers::GalleryFileHandler::GalleryInfo, node.node_info[:ginfo] )
    assert_equal( node.path, node.node_info[:ginfo].cur_gallery.pagename )
    assert_equal( 'gallery_gallery.template', node['template'] )

    node = root.resolve_node( 'Test.page' )
    assert_kind_of( FileHandlers::GalleryFileHandler::GalleryInfo, node.node_info[:ginfo] )
    assert_equal( 'gallery_main.template', node['template'] )

    # without a main page
    root.del_children
    @plugin.create_node( fixture_path( 'test1.gallery' ), root, {} )
    assert_not_nil( root.resolve_node( 'Test1.page' ) )
    assert_nil( root.resolve_node( 'Test1_1.page' ) )
    assert_nil( root.resolve_node( 'Test1_2.page' ) )
    assert_not_nil( root.resolve_node( 'Test1_test1_jpg.page' ) )
    assert_not_nil( root.resolve_node( 'Test1_test2_jpg.page' ) )
    assert_not_nil( root.resolve_node( 'Test1_test3_jpg.page' ) )
    assert_not_nil( root.resolve_node( 'Test1_test4_jpg.page' ) )

    node = root.resolve_node( 'Test1.page' )
    assert_kind_of( FileHandlers::GalleryFileHandler::GalleryInfo, node.node_info[:ginfo] )
    assert_equal( 'gallery_gallery.template', node['template'] )
  end

end

begin

  require 'RMagick'

  class ThumbnailWriterTest < Webgen::PluginTestCase

    plugin_files [
                  'webgen/plugins/filehandlers/directory.rb',
                  'webgen/plugins/filehandlers/gallery.rb'
                 ]
    plugin_to_test 'FileHandlers::ThumbnailWriter'

    def test_create_node
      node = @plugin.create_node( 'testfor\\anddo.jpg', nil, '100x100' )
      assert_equal( 'tn_testfor_anddo.jpg', node.path )
      assert_equal( 'testfor\\anddo.jpg', node.node_info[:thumbnail_file] )
      assert_equal( '100x100', node.node_info[:thumbnail_size] )
    end

    def test_gallery_thumbnail_creation
      root = Node.new( nil, '/' )
      root.node_info[:src] = ''

      @manager['FileHandlers::GalleryFileHandler'].create_node( fixture_path( 'test.gallery' ), root, {} )
      tn_node = root.resolve_node( 'tn_test1.jpg' )
      assert_not_nil( tn_node )
      assert_equal( '/test1.jpg', tn_node.node_info[:thumbnail_file] )
      assert_equal( tn_node.absolute_path, root.resolve_node( 'Test_test1_jpg.page' ).node_info[:ginfo].cur_image.data['thumbnail'] )
    end

  end

rescue LoadError
end
