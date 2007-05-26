require 'webgen/node'

module FileHandlers

  class DirectoryHandler < DefaultHandler

    # Specialized node for a directory.
    class DirNode < Node

      def initialize( parent, path, file_info )
        super( parent, path, file_info.cn )
        self.meta_info = file_info.meta_info
        self.node_info[:src] = file_info.filename
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
    def create_node( parent, file_info )
      path = output_name( parent, file_info )
      if parent.nil? || (node = node_exist?( parent, path, file_info.lcn )).nil?
        node = DirNode.new( parent, path + '/', file_info )
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
