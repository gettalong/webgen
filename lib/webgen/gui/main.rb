begin
  require 'RMagick'
rescue
  # do nothing
  # RMagick has to be loaded before Qt else an error occursr
end

require 'Qt'
require 'cgi'
require 'webgen/gui/common'
require 'webgen/gui/new_website_dlg'


class Object

  def self.set_logger( logger, set_it = false )
    @@logger = logger if set_it
  end

end

module Webgen::GUI

  ERROR_PALETTE = Qt::Palette.new( Qt::red.light, Qt::red.light )
  ERROR_PALETTE.setColor( Qt::Palette::Active, Qt::ColorGroup::Base, Qt::red.light )
  ERROR_PALETTE.setColor( Qt::Palette::Inactive, Qt::ColorGroup::Base, Qt::red.light )


  class Logger < Webgen::Logger

    def format_message( severity, timestamp, msg, progname )
      color = case severity
              when 'ERROR' then '#ff0000'
              when 'WARN' then '#880000'
              when 'INFO' then '#008800'
              when 'DEBUG' then '#aaaaaa'
              end
      msg.gsub!(/&/, '&amp;')
      msg.gsub!(/>/, '&gt;')
      msg.gsub!(/</, '&lt;')
      "<font color=#{color}><b>%s</b> %5s -- %s: %s</font>" % [timestamp, severity, progname, msg ]
    end

  end


  class LogWidget < Qt::TextEdit

    slots 'toggleShown()'

    # Create a LogWindow
    def initialize( p )
      super( p )
      setTextFormat( Qt::LogText )
      setFont( Qt::Font.new( "Courier" ) )
      Object.set_logger( Logger.new( self, 0, 0, logger.level ), true )
    end

    # Invoked by the logger library for writing log messages.
    def write( message )
      self.append( message )
    end

    # Invoked by the logger library for closing the log device. Does nothing.
    def close; end

    def toggleShown
      if isShown then hide else show end
    end

  end

  class MainWindow < Qt::MainWindow

    slots 'new()', 'open()', 'save()', 'preview_page()', 'preview_text()', 'filter_files()',
    'run_webgen()'

    def initialize
      super
      setCaption( 'webgen GUI' )
      setup_window
      setup_menus
      @website = Webgen::Website.new( '/home/thomas/work/projects/trunk/webgen/DIR' )
    end

    def new
      dlg = NewWebsiteDialog.new( self )
      if dlg.exec == Qt::Dialog::Accepted
        @website = Webgen::Website.new( dlg.website_directory )
        #TODO init website
      end
    end

    def open
      #TODO save files in existing dir if necessary
      dir = Qt::FileDialog.getExistingDirectory( @website.directory, self, nil, "Select website directory" )
      unless dir.nil?
        @website = Webgen::Website.new( dir )
        #TODO init website
      end
    end

    def save
      #TODO What to save???
    end

    def preview_page
      @old = @pageEditor.text
      @pageEditor.setTextFormat( Qt::RichText )
      @pageEditor.setText( RedCloth.new( @old ).to_html )
    end

    def preview_text
      @pageEditor.setTextFormat( Qt::PlainText )
      @pageEditor.setText( @old )
    end

    def filter_files
      # set_file_list
      # set status text
    end

    def run_webgen
      @log.clear
      before = Time.now
      Webgen.run_webgen( @website.directory )
      # call external command
      diff = Time.now - before
      puts diff
    end

    #######
    private
    #######

    def setup_menus
      filemenu = Qt::PopupMenu.new( self )
      filemenu.insertItem( "&Create website dir...", self, SLOT("new()"), Qt::KeySequence.new( CTRL+Key_N ) )
      filemenu.insertItem( "&Open website dir...", self, SLOT("open()"), Qt::KeySequence.new( CTRL+Key_O ) )
      filemenu.insertItem( "&Save website", self, SLOT("save()"), Qt::KeySequence.new( CTRL+Key_S ) )
      filemenu.insertSeparator
      filemenu.insertItem( "&Quit", $app, SLOT("quit()"), Qt::KeySequence.new( CTRL+Key_Q ) )

      toolsmenu = Qt::PopupMenu.new( self )
      toolsmenu.insertItem( "&Run webgen...", self, SLOT("run_webgen()"), Qt::KeySequence.new( CTRL+Key_R ) )
      toolsmenu.insertItem( "Toogle &log window", @log, SLOT('toggleShown()'), Qt::KeySequence.new( CTRL+Key_L) )

      self.menuBar.insertItem( "&File", filemenu )
      self.menuBar.insertItem( "&Tools", toolsmenu )
    end

    def setup_window
      mainWidget = Qt::Splitter.new( Qt::Vertical, self )
      mainWidget.setOpaqueResize( true )

      upperWidget = Qt::Widget.new( mainWidget )

      left = Qt::Widget.new( upperWidget )
      setup_file_list( left )
      setup_file_view( upperWidget )

      mainLayout = Qt::HBoxLayout.new( upperWidget )
      mainLayout.setSpacing( 3 )
      mainLayout.setMargin( 3 )
      mainLayout.addWidget( left )
      mainLayout.addWidget( @fileView, 1 )

      @log = LogWidget.new( mainWidget )
      @log.hide

      setCentralWidget( mainWidget )
    end

    def setup_file_list( mainWidget )
      button = Qt::PushButton.new( 'Clear', mainWidget )
      @filter = Qt::LineEdit.new( mainWidget )
      @filter.setMinimumWidth( 200 )

      connect( button, SIGNAL('clicked()'), @filter, SLOT('clear()') )
      connect( @filter, SIGNAL('textChanged(const QString&)'), self, SLOT('filter_files()') )

      @fileList = Qt::ListBox.new( mainWidget )

      @fileStatusText = Qt::Label.new( mainWidget )
      @fileStatusText.setText( 'something' )

      filterLayout = Qt::HBoxLayout.new
      filterLayout.addWidget( @filter )
      filterLayout.addWidget( button )

      layout = Qt::VBoxLayout.new( mainWidget )
      layout.setSpacing( 3 )
      layout.addLayout( filterLayout )
      layout.addWidget( @fileList )
      layout.addWidget( @fileStatusText )
    end

    def setup_file_view( mainWidget )
      @fileView = Qt::WidgetStack.new( mainWidget )
      @fileView.setMinimumSize( 300, 300 )

      main = Qt::Widget.new( @fileView )
      @pageEditor = Qt::TextEdit.new( main )
      @pageEditor.setTextFormat( Qt::PlainText )
      button = Qt::PushButton.new( "Preview", main )
      connect( button, SIGNAL('pressed()'), self, SLOT('preview_page()') )
      connect( button, SIGNAL('released()'), self, SLOT('preview_text()') )
      layout = Qt::VBoxLayout.new( main )
      layout.setSpacing( 3 )
      layout.addWidget( @pageEditor )
      layout.addWidget( button )


      @imageViewer = Qt::Label.new( @fileView )
    end

  end

end
