module Webgen::GUI

  class NewWebsiteDialog < Qt::Dialog

    slots 'choose_dir()', 'check_input()', 'create_website()'
    signals 'input_valid(bool)'

    def initialize( parent )
      super( parent )
      setCaption( "Create new website..." )
      setup_window
    end

    def setup_window
      layout = Qt::VBoxLayout.new( self, 10, 10 )

      mainLayout = Qt::GridLayout.new( 5, 2, 3 )

      mainLayout.addWidget( Qt::Label.new( "Directory:", self ), 0, 0 )
      box = Qt::HBoxLayout.new( 3 )
      @directory = Qt::LineEdit.new( self )
      @directory.setText( Dir.pwd )
      connect( @directory, SIGNAL('textChanged(const QString&)'), self, SLOT('check_input()') )
      dirChooser = Qt::PushButton.new( "...", self )
      connect( dirChooser, SIGNAL('clicked()'), self, SLOT('choose_dir()') )
      box.addWidget( @directory )
      box.addWidget( dirChooser )
      mainLayout.addLayout( box, 0, 1 )

      mainLayout.addWidget( Qt::Label.new( "Website name:", self ), 1, 0 )
      @website = Qt::LineEdit.new( self )
      @website.setFocus()
      connect( @website, SIGNAL('textChanged(const QString&)'), self, SLOT('check_input()') )
      mainLayout.addWidget( @website, 1, 1 )

      mainLayout.addWidget( Qt::Label.new( "Website template:", self ), 2, 0 )
      @template = Qt::ComboBox.new( self )
      @template.insertStringList( Webgen::Website.templates.sort )
      @template.setCurrentText( 'default' )
      mainLayout.addWidget( @template, 2, 1 )

      mainLayout.addWidget( Qt::Label.new( "Website style:", self ), 3, 0 )
      @style = Qt::ComboBox.new( self )
      @style.insertStringList( Webgen::Website.styles.sort )
      @style.setCurrentText( 'default' )
      mainLayout.addWidget( @style, 3, 1 )

      mainLayout.addWidget( Qt::Label.new( "Main language:", self ), 4, 0 )
      @language = Qt::ComboBox.new( self )
      @language.insertStringList( Webgen::Website.languages.collect {|l| l[1]}.sort )
      @language.setCurrentText( 'English' )
      mainLayout.addWidget( @language, 4, 1 )

      box = Qt::HBoxLayout.new( 3 )
      box.addStretch( 1 )
      @cancel = Qt::PushButton.new( "Cancel", self )
      connect( @cancel, SIGNAL('clicked()'), self, SLOT('reject()') )
      box.addWidget( @cancel )
      @create = Qt::PushButton.new( "Create", self )
      @create.setEnabled( false )
      connect( @create, SIGNAL('clicked()'), self, SLOT('create_website()') )
      connect( self, SIGNAL('input_valid(bool)'), @create, SLOT('setEnabled(bool)') )
      @create.setDefault( true )
      box.addWidget( @create )

      layout.addLayout( mainLayout )
      layout.addLayout( box )
      layout.setResizeMode( Qt::Layout::Fixed )

      check_input
    end

    def choose_dir
      newdir = Qt::FileDialog.getExistingDirectory( @directory.text, self, nil, "Select website base directory" )
      @directory.setText( newdir ) unless newdir.nil?
    end

    def check_input
      valid = true

      #check website parent dir
      if File.directory?( @directory.text )
        @directory.unsetPalette()
      else
        valid = false
        @directory.setPalette( Webgen::GUI::ERROR_PALETTE )
      end

      # check website name
      if @website.text.empty? || File.exists?( File.join( @directory.text, @website.text ) )
        valid = false
        @website.setPalette( Webgen::GUI::ERROR_PALETTE )
      else
        @website.unsetPalette()
      end

      emit input_valid( valid )
    end

    def website_directory
      File.join( @directory.text, @website.text )
    end

    #######
    private
    #######

    def create_website
      template = @template.currentText
      style = @style.currentText
      lang = Webgen::Website.languages.rassoc( @language.currentText )[0]
      begin
        Webgen.create_website( website_directory, template, style )
        File.open( File.join( website_directory, 'config.yaml' ), 'a+' ) {|f| f.write( "Configuration:\n  lang: #{lang}" ) }
      rescue RuntimeError, SystemCallError => e
        Qt::MessageBox.critical( self, "Creation error", "Could not create website: \n#{e.message}",
                                 Qt::MessageBox::Ok, Qt::MessageBox::NoButton, Qt::MessageBox::NoButton )
        return
      end
      accept
    end

  end

end
