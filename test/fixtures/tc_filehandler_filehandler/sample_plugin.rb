class SampleHandler < FileHandlers::DefaultHandler

  class PageNode < ::Node

    def =~( path )
      mypath = @path.sub( /de.html|en.html$/, 'html' )
      mypath2 = @path.sub( /html$/, 'page' )
      mypath3 = @path.sub( /de.html|en.html$/, 'page' )
      /^(#{mypath}|#{mypath2}|#{mypath3}|#{@path})/ =~ path
      $&
    end

  end

  register_path_pattern '**/*.page'
  register_extension 'page'

  default_meta_info( {'key'=>'value'} )

  def initialize( plugin_manager )
    super
    register_extension 'page'
    register_path_pattern '**/*.page'
  end

  def self.out_name( name )
    File.basename( name, '.page' ) + '.html'
  end

  def create_node( path, parent, meta_info )
    if (node = parent.find {|c| c.path == self.class.out_name( path )}).nil?
      node = PageNode.new( parent, self.class.out_name( path ) )
      node.node_info[:processor] = self
      node.meta_info.update( meta_info )
      node.meta_info.update( YAML::load( File.read( path ) ) ) rescue ''
      if node['lang']
        node['lang'] = Webgen::LanguageManager.language_for_code( node['lang'] )
      else
        node['lang'] = Webgen::LanguageManager.language_for_code( param( 'lang', 'Core/Configuration' ) )
      end
    end
    node
  end

  def node_for_lang( node, lang )
    node.parent.resolve_node( node.path.sub( /de.html|en.html$/, "#{lang}.html" ) )
  end

end
