module FileHandlers

  class DirectoryHandler < DefaultHandler

    # Specialized node for a directory.
    class DirNode < Node

      def initialize( parent, path, struct, meta_info = {} )
        super( parent, path, struct.cn )
        self.meta_info = meta_info
        self.node_info[:src] = struct.filename
        self['title'] = struct.title
      end

      def []( name )
        process_dir_index if name == 'indexFile' &&
          (!self.meta_info.has_key?( 'indexFile' ) ||
           (!self.meta_info['indexFile'].nil? && !self.meta_info['indexFile'].kind_of?( Node ) ) )
        super
      end

      #######
      private
      #######

      def process_dir_index
        indexFile = self.meta_info['indexFile']
        if indexFile.nil?
          self['indexFile'] = nil
        else
          node = resolve_node( indexFile )
          if node
            node_info[:processor].log(:info) { "Directory index file for <#{self.full_path}> => <#{node.full_path}>" }
            self['indexFile'] = node
          else
            node_info[:processor].log(:warn) { "No directory index file found for directory <#{self.full_path}>" }
            self['indexFile'] = nil
          end
        end
      end

    end

    # Returns a new DirNode.
    def create_node( struct, parent, meta_info )
      filename = File.basename( struct.filename ) + '/'
      if parent.nil? || (node = @plugin_manager['Core/FileHandler'].node_exist?( parent, filename )).nil?
        node = DirNode.new( parent, filename, struct, meta_info )
        node.node_info[:processor] = self
      end
      node
    end

    # Creates the directory (and all its parent directories if necessary).
    def write_info( node )
      {:src => node.node_info[:src]}
    end

    # Return the page node for the directory +node+ using the specified language +lang+. If an
    # index file is specified, then the its correct language node is returned, else +node+ is
    # returned.
    def node_for_lang( node, lang )
      langnode = node['indexFile'].node_for_lang( lang ) if node['indexFile']
      langnode || node
    end

    # See DefaultFileHandler#link_from and PageHandler#link_from.
    def link_from( node, ref_node, attr = {} )
      lang_node = (attr[:resolve_lang_node] == false ? node : node.node_for_lang( ref_node['lang'] ) ) #TODO still necessary?
      attr[:link_text] ||=  lang_node['directoryName'] || node['title']
      super( lang_node, ref_node, attr )
    end

    # Recursively creates a given directory path starting from the path of +parent+ and returns the
    # bottom most directory node.
    def recursive_create_path( path, parent )
      path.split( File::SEPARATOR ).each do |pathname|
        case pathname
        when '.' then  #do nothing
        when '..' then parent = parent.parent
        else parent = @plugin_manager['Core/FileHandler'].create_node( pathname, parent, self )
        end
      end
      parent
    end

  end

end
