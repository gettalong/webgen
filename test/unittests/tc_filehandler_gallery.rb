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
    @galleries << gclass.new( 'gal1.html',
                              [iclass.new( 'test1.html', 'test1.jpg', {'thumbnail' => 'tn_test1.jpg'} ), iclass.new( 'test2.html', 'test2.jpg', {'thumbnailSize' => '100x50'} )],
                              {} )
    @galleries << gclass.new( 'gal2.html',
                              [iclass.new( 'test3.html', 'test3.jpg', {} ), iclass.new( 'test4.html', 'test4.jpg', {} )],
                              {} )
    @galleries << gclass.new( 'gal3.html',
                              [iclass.new( 'test5.html', 'test5.jpg', {} ), iclass.new( 'test6.html', 'test6.jpg', {} )],
                              {} )
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
    assert_equal( '<img src="tn_test1.jpg" alt="" />', ginfo.cur_image.thumbnail )
    assert_equal( '<img src="test2.jpg" width="100" height="50" alt="" />', ginfo.next_image.thumbnail )
  end

  def test_gallery_accessors
    ginfo = FileHandlers::GalleryFileHandler::GalleryInfo.new( @galleries, 0, 0 )
    assert_equal( '<img src="tn_test1.jpg" alt="" />', ginfo.cur_gallery.thumbnail )
    assert_equal( '<img src="test3.jpg" width="" height="" alt="" />', ginfo.next_gallery.thumbnail )
  end

end

class GalleryFileHandlerTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/gallery.rb'
  ]
  plugin_to_test 'FileHandlers::GalleryFileHandler'

  def test_create_node
    root = Node.new( nil, '/' )

    # with a main page
    @plugin.create_node( fixture_path( 'test.gallery' ), root )
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
    @plugin.create_node( fixture_path( 'test1.gallery' ), root )
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
