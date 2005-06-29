require 'yaml'
require 'ostruct'
require 'webgen/plugin'
require 'webgen/configuration'
require 'webgen/plugins/filehandler/picturegallery'
require 'Qt'
# Error when loading Qt before RMagick -> error in RMagick undefined method `display' for class `Magick::Image'
# report that to qtruby team and RMagick team

#TODO

class Gallery

  attr_accessor :meta
  attr_accessor :relpath

  def initialize
    set_default_values
  end

  def []( name )
    @meta[name]
  end

  def []=( name, value )
    @meta[name] = value
  end

  def set_default_values
    @meta = {}
    Webgen::Plugin.config[FileHandlers::PictureGalleryFileHandler].params.each do |name, data|
      @meta[name] = data.value
    end
    @meta['mainPage'] = nil
    @meta['galleryPages'] = nil
    @meta['thumbnailSize'] = nil
  end

  def read_file( filename )
    filedata = YAML::load( File.read( filename ) )

    set_default_values
    filedata.each {|name, data| @meta[name] = data }
    @relpath = File.dirname( filename )
  end

  def write_file( filename )
    File.open( filename, 'w+' ) {|file| file.write( @meta.to_yaml ) }
  end

end


class ImageViewer < Qt::Frame

  def initialize( p )
    super( p )
    setFrameStyle( Qt::Frame::StyledPanel | Qt::Frame::Sunken )
    @image = nil
  end

  def set_image( filename )
    @image = Qt::Image.new( filename )
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


class MetaTableNameItem < Qt::TableItem

  def initialize( table, text = '' )
    super( table, Qt::TableItem::WhenCurrent )
    setText( text )
    add_text_to_list( text )
  end

  def createEditor
    cb = Qt::ComboBox.new( table.viewport )
    cb.setEditable( true )
    cb.setAutoCompletion( true )
    cb.insertStringList( table.meta_items )
    #Qt::Object.connect( cb, SIGNAL('activated(int)'), table, SLOT('doValueChanged()') )
    cb.setCurrentText( text )
    cb
  end

  def setContentFromEditor( widget )
    setText( widget.currentText )
    add_text_to_list( widget.currentText )
  end

  def add_text_to_list( text )
    unless text.nil? || text.empty? || table.meta_items.include?( text )
      table.meta_items << text
      table.meta_items.sort!
    end
  end

end

class MetaTableValueItem < Qt::TableItem

  def initialize( table, text = '' )
    super( table, Qt::TableItem::OnTyping )
    setContent( text )
  end

  def setContent( content )
    setText( content.to_s )
  end

  def getContent
    content = text
    if content == 'true'
      true
    elsif content == 'false'
      false
    elsif content == 'nil'
      nil
    elsif content =~ /\d+/
      content.to_i
    else
      content
    end
  end

end


class MetaDataTable < Qt::Table

  slots 'value_changed(int, int)'

  attr_reader :meta_items

  def initialize( p, meta_items = [], exclude_items = [] )
    super( 1, 2, p )
    @meta_items = meta_items.sort!
    @exclude_items = exclude_items
    horizontalHeader.setLabel( 0, 'Name' )
    horizontalHeader.setLabel( 1, 'Value' )
    setSelectionMode( Qt::Table::Single )
    connect( self, SIGNAL('valueChanged(int, int)'), self, SLOT('value_changed( int, int )') )
    setItem( 0, 0, MetaTableNameItem.new( self ) )
    setItem( 0, 1, MetaTableValueItem.new( self ) )
  end

  def activateNextCell
    activate = endEdit( currentRow, currentColumn, true, false )
    oldRow = currentRow
    oldCol = currentColumn

    setCurrentCell( currentColumn == 1 ? (currentRow == numRows - 1 ? 0 : currentRow + 1) : currentRow,
                    (currentColumn + 1) % 2 )
    setCurrentCell( oldRow, oldCol ) if !activate
  end

  def endEdit( row, col, accept, replace )
    activate_next_cell = true
    w = cellWidget( row, col )
    if col == 0 && !w.nil?
      if keys( (0...row).to_a + (row+1..numRows-1).to_a ).find {|t| t == w.currentText && t != '' }
        msg = "You can't add duplicate entries!"
      elsif @exclude_items.include?( w.currentText )
        msg = "This meta information can only be defined via other controls!"
      end
      if msg
        Qt::MessageBox.information( self, "Error adding entry", msg )
        accept = false
        activate_next_cell = false
      end
    end
    super( row, col, accept, replace )
    activate_next_cell
  end

  def fill( items )
    setNumRows( items.length + 1 )
    items.each_with_index do |data, index|
      setItem( index, 0, MetaTableNameItem.new( self, data[0] ) )
      setItem( index, 1, MetaTableValueItem.new( self, data[1] ) )
    end
    setItem( items.length, 0, MetaTableNameItem.new( self ) )
    setItem( items.length, 1, MetaTableValueItem.new( self ) )
  end

  def keys( rows = (0..(numRows-1)).to_a )
    retval = []
    rows.each do |i|
      retval << text( i, 0 )
    end
    retval
  end

  def meta_info
    retval = {}
    0.upto( numRows - 2 ) do |i|
      retval[text( i, 0 )] = item( i, 1 ).getContent
    end
    retval
  end

  def value_changed( row, col )
    col0empty = text( row, 0 ).nil? || text( row, 0).empty?
    col1empty = text( row, 1 ).nil? || text( row, 1).empty?
    if row == numRows - 1 && (!col0empty || !col1empty)
      setNumRows( numRows + 1 )
      setItem( numRows - 1, 0, MetaTableNameItem.new( self ) )
      setItem( numRows - 1, 1, MetaTableValueItem.new( self ) )
    elsif !(row == numRows - 1) && col0empty && col1empty
      removeRow( row )
    end
  end

end


class GalleryWindow < Qt::MainWindow

  slots 'new()', 'open()', 'save()', 'save_as()', 'image_selected(const QString &)',
        'init_image_list()'

  def initialize
    super
    setCaption( "Webgen Gallery Editor" )
    setIcon( Qt::Pixmap.new( File.join( Webgen::Configuration.data_dir, 'images/webgen_logo.png' ) ) )
    setIconText( "Webgen Gallery Editor" )

    @gallery = nil
    @curfile = nil
    setup_menus
    setup_window
    new
  end

  def new
    @gallery = Gallery.new
    init_widgets
  end

  def open
    openDialog = Qt::FileDialog.new( '.', 'Gallery files (*.gallery)', self, 'Open File Dialog', true )
    openDialog.setMode( Qt::FileDialog::ExistingFile )
    open_file( openDialog.selectedFile ) if openDialog.exec == Qt::Dialog::Accepted
  end

  def open_file( file )
    @curfile = file
    @gallery = Gallery.new
    @gallery.read_file( file )
    init_widgets
  end

  def save
    update_gallery
    @gallery.write_file( @curfile )
  end

  def save_as
    saveDialog = Qt::FileDialog.new( '.', 'Gallery files (*.gallery)', self, 'Open File Dialog', true )
    saveDialog.setMode( Qt::FileDialog::AnyFile )
    if saveDialog.exec == Qt::Dialog::Accepted
      fname = saveDialog.selectedFile
      fname += '.gallery' if File.extname( fname ) == ''
      #TODO update rel path of images
      @gallery.write_file( fname )
    end
  end

  def image_selected( name )
    @gallery[@last_selected_image] = @picMetaTable.meta_info if @last_selected_image
    @last_selected_image = name
    @picMetaTable.fill( @gallery[name] ) if @gallery[name]
    @image.set_image( File.join( @gallery.relpath, name ) )
  end

  #######
  private
  #######

  def page_meta_items
    ['title', 'description', 'orderInfo', 'template', 'inMenu']
  end

  def gallery_items
    ['title', 'layout', 'files', 'picturesPerPage',
     'picturePageInMenu', 'galleryPageInMenu', 'mainPageInMenu',
     'picturePageTemplate', 'galleryPageTemplate', 'mainPageTemplate',
     'galleryPages', 'mainPage', 'galleryOrderInfo', 'thumbnailSize' ]
  end

  def init_widgets
    return if @gallery.nil?

    gallery_items.each do |t|
      case @gallery[t]
      when String then @widgets[t].setText( @gallery[t] )
      when Integer then @widgets[t].setValue( @gallery[t] )
      when TrueClass, FalseClass then @widgets[t].setChecked( @gallery[t] )
      when Hash then @widgets[t].fill( @gallery[t] )
      end
    end
    @picMetaTable.fill( [] )
    init_image_list
  end

  def update_gallery
    items = gallery_items
    items.each do |t|
      case @widgets[t]
      when Qt::LineEdit then @gallery[t] = @widgets[t].text
      when Qt::SpinBox then @gallery[t] = @widgets[t].value
      when Qt::CheckBox then @gallery[t] = @widgets[t].checked?
      when MetaDataTable then @gallery[t] = @widgets[t].meta_info
      end
    end
    images = []
    0.upto( @imageList.numRows ) {|i| images << @imageList.text( i ) }
    @gallery[@imageList.currentText] = @picMetaTable.meta_info
    @gallery.meta.delete_if do |name, data|
      !images.include?( name ) && !items.include?( name )
    end
  end

  def init_image_list
    @imageList.clear
    images = Dir[File.join( @gallery.relpath, @widgets['files'].text)].collect {|i| i.sub( /#{@gallery.relpath + File::SEPARATOR}/, '' ) }
    images.each {|i| @imageList.insertItem( i ) }
    @last_selected_image = nil
  end

  def setup_menus
    filemenu = Qt::PopupMenu.new( self )
    filemenu.insertItem( "&New...", self, SLOT("new()"), Qt::KeySequence.new( CTRL+Key_N ) )
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

    # setup image frame
    imageFrame = Qt::Widget.new( tabwidget )

    @image = ImageViewer.new( imageFrame )
    @image.setSizePolicy( Qt::SizePolicy::Expanding, Qt::SizePolicy::Expanding )
    @image.setMinimumSize( Qt::Size.new( 640, 480 ) )
    @image.set_image( File.join( Webgen::Configuration.data_dir, 'images/webgen_logo.png' ) )

    @imageList = Qt::ListBox.new( imageFrame )
    @imageList.setMaximumWidth( 300 )
    @imageList.setMinimumWidth( 300 )
    connect( @imageList, SIGNAL('highlighted(const QString &)'), self, SLOT('image_selected( const QString &)') )
    @picMetaTable = MetaDataTable.new( imageFrame, page_meta_items )

    mainLayout = Qt::GridLayout.new( imageFrame, 2, 2 )
    mainLayout.setMargin( 11 )
    mainLayout.setSpacing( 6 )
    mainLayout.addMultiCellWidget( @image, 0, 1, 0, 0 )
    mainLayout.addWidget( @imageList, 0, 1 )
    mainLayout.addWidget( @picMetaTable, 1, 1 )

    # setup gallery frame
    galleryFrame = Qt::Widget.new( tabwidget )

    @widgets = {}
    labels = {}
    @widgets['title'] = Qt::LineEdit.new( galleryFrame )
    labels['title'] = [0, Qt::Label.new( @widgets['title'], "Gallery title:", galleryFrame )]
    @widgets['files'] = Qt::LineEdit.new( galleryFrame )
    connect( @widgets['files'], SIGNAL('textChanged(const QString&)'), self, SLOT('init_image_list()') )
    labels['files'] = [1, Qt::Label.new( @widgets['files'], "File pattern:", galleryFrame )]
    @widgets['layout'] = Qt::LineEdit.new( galleryFrame )
    labels['layout'] = [2, Qt::Label.new( @widgets['layout'], "Gallery layout:", galleryFrame )]
    @widgets['picturesPerPage'] = Qt::SpinBox.new( 0, 1000, 1, galleryFrame )
    labels['picturesPerPage'] = [3, Qt::Label.new( @widgets['picturesPerPage'], "Pictures per page:", galleryFrame )]
    @widgets['galleryOrderInfo'] = Qt::SpinBox.new( 0, 1000, 1, galleryFrame )
    labels['galleryOrderInfo'] = [4, Qt::Label.new( @widgets['galleryOrderInfo'], "Meta info <orderInfo> for first gallery page:", galleryFrame )]
    @widgets['thumbnailSize'] = Qt::LineEdit.new( galleryFrame )
    @widgets['thumbnailSize'].setValidator( Qt::RegExpValidator.new( Qt::RegExp.new( "\\d+x\\d+" ), galleryFrame ) )
    labels['thumbnailSize'] = [5, Qt::Label.new( @widgets['thumbnailSize'], "Thumbnail size:", galleryFrame )]
    @widgets['mainPageTemplate'] = Qt::LineEdit.new( galleryFrame )
    labels['mainPageTemplate'] = [6, Qt::Label.new( @widgets['mainPageTemplate'], "Template for main page:", galleryFrame )]
    @widgets['galleryPageTemplate'] = Qt::LineEdit.new( galleryFrame )
    labels['galleryPageTemplate'] = [7, Qt::Label.new( @widgets['galleryPageTemplate'], "Template for gallery pages:", galleryFrame )]
    @widgets['picturePageTemplate'] = Qt::LineEdit.new( galleryFrame )
    labels['picturePageTemplate'] = [8, Qt::Label.new( @widgets['picturePageTemplate'], "Template for picture pages:", galleryFrame )]
    @widgets['mainPageInMenu'] = Qt::CheckBox.new( "Main page in menu?", galleryFrame )
    labels['mainPageInMenu'] = [9, nil]
    @widgets['galleryPageInMenu'] = Qt::CheckBox.new( "Gallery pages in menu?", galleryFrame )
    labels['galleryPageInMenu'] = [10, nil]
    @widgets['picturePageInMenu'] = Qt::CheckBox.new( "Picture pages in menu?", galleryFrame )
    labels['picturePageInMenu'] = [11, nil]

    layout = Qt::GridLayout.new( @widgets.length, 2 )
    layout.setSpacing( 5 )
    labels.each_with_index do |data, index|
      layout.addWidget( data[1][1], data[1][0], 0 ) if data[1][1]
      layout.addWidget( @widgets[data[0]], data[1][0], 1 )
    end

    leftLayout = Qt::VBoxLayout.new
    leftLayout.setSpacing( 5 )
    leftLayout.addLayout( layout )
    leftLayout.addStretch

    @widgets['mainPage'] = MetaDataTable.new( galleryFrame, page_meta_items )
    @widgets['mainPage'].setColumnWidth( 0, 200 )
    @widgets['mainPage'].setColumnWidth( 1, 200 )
    @widgets['galleryPages'] = MetaDataTable.new( galleryFrame, page_meta_items )
    @widgets['galleryPages'].setColumnWidth( 0, 200 )
    @widgets['galleryPages'].setColumnWidth( 1, 200 )

    rightLayout = Qt::VBoxLayout.new
    rightLayout.setSpacing( 5 )
    rightLayout.addWidget( Qt::Label.new( 'Meta information for main page:', galleryFrame ) )
    rightLayout.addWidget( @widgets['mainPage'] )
    rightLayout.addWidget( Qt::Label.new( 'Meta information for gallery pages:', galleryFrame ) )
    rightLayout.addWidget( @widgets['galleryPages'] )

    mainLayout = Qt::HBoxLayout.new( galleryFrame )
    mainLayout.setMargin( 10 )
    mainLayout.setSpacing( 20 )
    mainLayout.addLayout( leftLayout )
    mainLayout.addLayout( rightLayout )

    # setup tabwidget
    tabwidget.addTab( galleryFrame, "Gallery Meta Information" )
    tabwidget.addTab( imageFrame, "Images" )
  end

end


$app = Qt::Application.new( ARGV )
mainWindow = GalleryWindow.new
mainWindow.setIcon( Qt::Pixmap.new( File.join( Webgen::Configuration.data_dir, 'images/webgen_logo.png' ) ) )
$app.setMainWidget( mainWindow )
mainWindow.show
mainWindow.open_file( ARGV[0] ) if ARGV.length > 0
$app.exec
