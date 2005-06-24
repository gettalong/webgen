require 'yaml'
require 'ostruct'
require 'webgen/plugin'
require 'webgen/configuration'
require 'webgen/plugins/filehandler/picturegallery'
require 'Qt'
# Error when loading Qt before RMagick -> error in RMagick undefined method `display' for class `Magick::Image'
# report that to qtruby team and RMagick team


class Gallery

  attr_accessor :meta
  attr_accessor :relpath

  def initialize
    @meta = {}
    set_default_values
  end

  def []( name )
    @meta[name].value if @meta.has_key?( name )
  end

  def set_default_values
    config = Webgen::Plugin.config[FileHandlers::PictureGalleryFileHandler]
    config.params.each do |name, data|
      @meta[name] = OpenStruct.new( :value => data.default, :desc => data.description )
    end
    @meta['mainPage'] = OpenStruct.new( :value => nil, :desc => 'Meta information for the main page' )
    @meta['galleryPages'] = OpenStruct.new( :value => nil, :desc => 'Meta information for the gallery pages' )
    @meta['thumbnailSize'] = OpenStruct.new( :value => nil, :desc => 'Thumbnail size for pictures' )
  end

  def read_file( filename )
    filedata = YAML::load( File.read( filename ) )

    filedata.each do |name, data|
      if @meta.has_key?( name )
        @meta[name].value = data
      else
        @meta[name] = OpenStruct.new( :value => data, :desc => 'Unknown meta information' )
      end
    end
    @relpath = File.dirname( filename )
  end

  def write_file( filename )
    filedata = {}
    @meta.each do |name, data|
      filedata[name] = data.value
    end
    File.open( filename, 'w+' ) {|file| file.write( filedata.to_yaml ) }
  end

end


class ImageViewer < Qt::Frame

  def initialize( p )
    super( p )
    setFrameStyle( Qt::Frame::StyledPanel | Qt::Frame::Sunken )
    @image = nil
  end

  def set_image( image )
    @image = image
    update
  end

  def drawContents( painter )
    return if @image.nil?
    width = contentsRect.width
    height = contentsRect.height
    image = ( width > @image.width && height > @image.height ? @image : @image.smoothScale( width, height, Qt::Image::ScaleMin ) )
    painter.drawImage( contentsRect.left + (width - image.width) / 2, contentsRect.top + (height - image.height) / 2, image )
  end

  def sizeHint
    Qt::Size.new( 640, 480 )
  end

end

class MetaDataTable < Qt::Table

  def initialize( p )
    super( p )
  end

end

class GalleryWindow < Qt::MainWindow

  slots 'new()', 'open()', 'save()', 'save_as()', 'imageSelected(const QString &)',
        'meta_value_changed(int, int)'

  def initialize
    super

    @gallery = nil

    setup_menus
    setup_window
  end

  def new
  end

  def open
    openDialog = Qt::FileDialog.new( '.', 'Gallery files (*.gallery)', self, 'Open File Dialog', true )
    openDialog.setMode( Qt::FileDialog::ExistingFile )
    if openDialog.exec == Qt::Dialog::Accepted
      fname = openDialog.selectedFile
      @gallery = Gallery.new
      @gallery.read_file( fname )
      init_widgets
    end
  end

  def save
  end

  def save_as
  end


  def imageSelected( name )
    # @image.setPixmap( Qt::Pixmap.new( File.join( @gallery.relpath, name ) ) )
    @image.set_image( Qt::Image.new( File.join( @gallery.relpath, name ) ) )
    if @gallery[name]
      @metadataTable.setNumRows( @gallery[name].length + 1)
      @gallery[name].each_with_index do |data, index|
        @metadataTable.setText( index, 0, data[0] )
        @metadataTable.setText( index, 1, data[1] )
      end
      @metadataTable.setText( @gallery[name].length, 0, '' )
      @metadataTable.setText( @gallery[name].length, 1, '' )
    end
  end

  def meta_value_changed( row, col )
    if row == @metadataTable.numRows - 1 && \
      (!@metadataTable.text( row, 0 ).empty? || !@metadataTable.text( row, 1 ).empty?)
      @metadataTable.setNumRows( @metadataTable.numRows + 1 )
    elsif @metadataTable.text( row, 0 ).empty? && @metadataTable.text( row, 1 ).empty?
      @metadataTable.removeRow( row )
    end
  end

  #######
  private
  #######

  def init_widgets
    return if @gallery.nil?

    @imageList.clear
    images = Dir[File.join( @gallery.relpath, @gallery['files'])].collect {|i| i.sub( /#{@gallery.relpath + File::SEPARATOR}/, '' ) }
    images.each {|i| @imageList.insertItem( i ) }
  end

  def setup_menus
    filemenu = Qt::PopupMenu.new( self )
    filemenu.insertItem( "&Open...", self, SLOT("open()"), Qt::KeySequence.new( CTRL+Key_O ) )
    filemenu.insertItem( "&Save", self, SLOT("save()"), Qt::KeySequence.new( CTRL+Key_S ) )
    filemenu.insertItem( "&Save as...", self, SLOT("save_as()") )
    filemenu.insertItem( "&Quit", $app, SLOT("quit()"), Qt::KeySequence.new( CTRL+Key_Q ) )

    menubar = Qt::MenuBar.new( self )
    menubar.insertItem( "&File", filemenu )
  end

  def setup_window
    tabwidget = Qt::TabWidget.new( self )
    setCentralWidget( tabwidget )

    imageFrame = Qt::Frame.new( tabwidget )

    @image = ImageViewer.new( imageFrame )
    @image.setSizePolicy( Qt::SizePolicy::Expanding, Qt::SizePolicy::Expanding )
    @image.setMinimumSize( Qt::Size.new( 640, 480 ) )
    @image.set_image( Qt::Image.new( File.join( Webgen::Configuration.data_dir, 'images/webgen_logo.png' ) ) )

    @imageList = Qt::ListBox.new( imageFrame )
    @imageList.setMaximumWidth( 300 )
    @imageList.setMinimumWidth( 300 )
    connect( @imageList, SIGNAL('highlighted(const QString &)'), self, SLOT('imageSelected( const QString &)') )
    @metadataTable = Qt::Table.new( 1, 2, imageFrame )
    @metadataTable.setMaximumWidth( 300 )
    @metadataTable.horizontalHeader.setLabel( 0, 'Meta info name' )
    @metadataTable.horizontalHeader.setLabel( 1, 'Meta info value' )
    connect( @metadataTable, SIGNAL('valueChanged(int, int)'), self, SLOT('meta_value_changed( int, int )') )


    mainLayout = Qt::GridLayout.new( imageFrame, 2, 2 )
    mainLayout.setMargin( 11 )
    mainLayout.setSpacing( 6 )
    mainLayout.addMultiCellWidget( @image, 0, 1, 0, 0 )
    mainLayout.addWidget( @imageList, 0, 1 )
    mainLayout.addWidget( @metadataTable, 1, 1 )

    tabwidget.addTab( imageFrame, "Images" )
  end

end


$app = Qt::Application.new( ARGV )
mainWindow = GalleryWindow.new
mainWindow.show
$app.setMainWidget( mainWindow )
$app.exec
