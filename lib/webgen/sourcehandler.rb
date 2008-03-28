module Webgen

  module SourceHandler

    autoload :Base, 'webgen/sourcehandler/base'
    autoload :Copy, 'webgen/sourcehandler/copy'
    autoload :Directory, 'webgen/sourcehandler/directory'

    class Main

      include WebsiteAccess

      def intialize
        website.blackboard.add_service(:create_nodes, method(:create_nodes))
      end

      def find_all_source_paths
        if !@paths
          source = Webgen::Source::Stacked.new(Hash[*website.config['sources'].collect do |mp, name, *args|
                                                      [mp, constant(name).new(*args)]
                                                    end.flatten])
          @paths = {}
          source.paths.each {|p| @paths[p.path] = p}
          @paths.delete('/')
        end
        @paths
      end

      def paths_for_handler(name)
        patterns = website.config['sourcehandler.patterns'][name]
        return [] if patterns.nil?

        options = (website.config['sourcehandler.casefold'] ? File::FNM_CASEFOLD : 0) |
          (website.config['sourcehandler.usehiddenfiles'] ? File::FNM_DOTMATCH : 0)
        find_all_source_paths.select do |pathname, path|
          patterns.any? {|pat| File.fnmatch(pat, path, options)}
        end
      end

      def create_nodes_from_paths(tree)
        website.config['sourcehandler.invoke'].sort.each do |priority, shns|
          shns.each do |shn|
            sh = constant(shn).new
            paths_for_handler(shn).sort.each do |pathname, path|
              create_nodes(tree, File.join(File.dirname(path.path), '/'), path) do |parent|
                sh.create_node(parent, path)
              end
            end
          end
        end
      end

      # Prepares everything to create nodes under the absolute lcn path +parent_path_name+ in the +tree
      # from the +path+ and yields the needed parent node. After the nodes are created, it is also
      # checked if they have all needed properties.
      def create_nodes(tree, parent_path_name, path)
        if !(parent = tree.node_access[parent_path_name])
          raise "The specified parent path <#{parent_path_name}> does not exist"
        end
        #TODO: metainfo
        *nodes = yield(parent)
        nodes.compact.each do |node|
          node.node_info[:src] = path.path
          website.blackboard.dispatch_msg(:node_created, node)
        end
        nodes
      end

    end

  end

end
