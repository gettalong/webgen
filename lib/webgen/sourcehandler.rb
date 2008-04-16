module Webgen

  module SourceHandler

    autoload :Base, 'webgen/sourcehandler/base'
    autoload :Copy, 'webgen/sourcehandler/copy'
    autoload :Directory, 'webgen/sourcehandler/directory'
    autoload :Metainfo, 'webgen/sourcehandler/metainfo'

    class Main

      include WebsiteAccess

      def initialize
        website.blackboard.add_service(:create_nodes, method(:create_nodes))
        website.blackboard.add_service(:source_paths, method(:find_all_source_paths))
      end

      def render(tree)
        paths = Set.new(find_all_source_paths.keys) - clean(tree)
        create_nodes_from_paths(tree, paths)
        paths = Set.new(find_all_source_paths.keys) - paths - clean(tree)
        create_nodes_from_paths(tree, paths)

        tree.node_access.each do |name, node|
          puts "#{name} (#{node.meta_info['title']})".ljust(80) + "#{node.changed? ? '' : 'not '}dirty " + node.dirty.to_s + " " + node.created.to_s
        end
        tree.node_access.each do |name, node|
          node.dirty = false
          node.created = false
        end
      end

      private

      def find_all_source_paths
        if !@paths
          source = Webgen::Source::Stacked.new(Hash[*website.config['sources'].collect do |mp, name, *args|
                                                      [mp, constant(name).new(*args)]
                                                    end.flatten])
          @paths = {}
          source.paths.each do |path|
            if !(website.config['sourcehandler.ignore'].any? {|pat| File.fnmatch(pat, path, File::FNM_CASEFOLD|File::FNM_DOTMATCH)})
              @paths[path.path] = path
            end
          end
          @paths.delete('/')
        end
        @paths
      end

      def paths_for_handler(name, paths)
        patterns = website.config['sourcehandler.patterns'][name]
        return [] if patterns.nil?

        options = (website.config['sourcehandler.casefold'] ? File::FNM_CASEFOLD : 0) |
          (website.config['sourcehandler.usehiddenfiles'] ? File::FNM_DOTMATCH : 0)
        find_all_source_paths.values_at(*paths).select do |path|
          patterns.any? {|pat| File.fnmatch(pat, path, options)}
        end
      end

      def create_nodes_from_paths(tree, paths)
        website.config['sourcehandler.invoke'].sort.each do |priority, shns|
          shns.each do |shn|
            sh = website.cache.instance(shn)
            paths_for_handler(shn, paths).sort.each do |path|
              create_nodes(tree, File.join(path.directory.split('/').collect {|p| Path.new(p).cn}.join('/'), '/'), path) do |parent|
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
        website.blackboard.dispatch_msg(:before_node_created, parent, path)
        *nodes = yield(parent)
        nodes.compact.each do |node|
          node.node_info[:src] = path.path
          website.blackboard.dispatch_msg(:after_node_created, node)
        end
        nodes
      end


      #TODO: doc
      def clean(tree)
        # Remove nodes w/o path, w/ changed path or where node changed
        paths_to_delete = Set.new
        paths_not_to_delete = Set.new
        tree.node_access.values.each do |node|
          deleted = !find_all_source_paths.include?(node.node_info[:src])
          if !node.created && (deleted ||
                               find_all_source_paths[node.node_info[:src]].changed? ||
                               node.changed?)
            tree.delete_node(node, deleted)
            paths_not_to_delete << node.node_info[:src]
          else
            paths_to_delete << node.node_info[:src]
          end
        end

        # source paths that should be used
        paths_to_delete - paths_not_to_delete
      end

    end

  end

end
