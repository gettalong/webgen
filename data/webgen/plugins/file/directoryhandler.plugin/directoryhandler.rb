require 'webgen/node'
require 'facets/basicobject'

module FileHandlers

  class DirectoryHandler < DefaultHandler

    # Specialized delegation node for the index file of a directory. Behaves exactly like the index
    # file node of a directory except for the #link_from and #node_for_lang methods which are altered
    # to do the "right thing".
    class DelegateIndexNode < BasicObject

      ["inspect", "instance_variable_defined?", "equal?", "respond_to?", "object_class",
       "instance_variables", "eql?", "object_id", "instance_variable_get", "frozen?", "instance_of?",
       "instance_variable_set", "kind_of?", "tainted?", "nil?", "is_a?"].each {|m| undef_method m rescue nil}

      def initialize( dir_node, index_node )
        @dir_node = dir_node
        @index_node = index_node
      end

      def method_missing( sym, *args, &block )
        @index_node.send( sym, *args, &block )
      end

      def node_for_lang( lang )
        lang_node = @index_node.node_for_lang( lang )
        (lang_node.nil? ? nil : DelegateIndexNode.new( @dir_node, lang_node ) )
      end

      def link_from( ref_node, attr = {} )
        attr[:link_text] ||=  @index_node['directoryName'] || @dir_node['title']
        @index_node.link_from( ref_node, attr )
      end

    end

    # Specialized node for a directory.
    class DirNode < Node

      def initialize( parent, path, file_info )
        super( parent, path, file_info.cn, file_info.meta_info )
        self.node_info[:src] = file_info.filename
      end

      def []( name )
        return super unless name == 'indexFile'
        resolve_dir_index unless node_info.has_key?( :indexFile )
        node_info[:indexFile]
      end

      #######
      private
      #######

      def resolve_dir_index
        indexFile = self.meta_info['indexFile']
        if indexFile.nil?
          node_info[:indexFile] = nil
        else
          node = resolve_node( indexFile )
          if node
            node_info[:processor].log(:info) { "Directory index file for <#{self.full_path}> => <#{node.full_path}>" }
            node_info[:indexFile] = DelegateIndexNode.new( self, node )
          else
            node_info[:processor].log(:warn) { "No directory index file found for directory <#{self.full_path}>" }
            node_info[:indexFile] = nil
          end
        end
      end

    end

    # Returns a new DirNode.
    def create_node( parent, file_info )
      path = output_name( parent, file_info )
      # the warnings for node_exist? are suppressed because of recursive_create_path
      if parent.nil? || (node = node_exist?( parent, path, file_info.lcn, false )).nil?
        node = DirNode.new( parent, path + '/', file_info )
        node.node_info[:processor] = self
      end
      node
    end

    # Creates the directory (and all its parent directories if necessary).
    def write_info( node )
      {:src => node.node_info[:src]}
    end

    # Return the page node for the directory +node+ using the specified language +lang+. If an index
    # file is specified, then its correct language node is returned, else +node+ is returned.
    def node_for_lang( node, lang )
      lang_node = node['indexFile'].node_for_lang( lang ) if node['indexFile']
      lang_node || (node.parent.nil? ? node : super)
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
