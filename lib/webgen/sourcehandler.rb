require 'webgen/loggable'
require 'benchmark'

module Webgen

  # Namespace for all classes that handle source paths.
  #
  # Have a look at Webgen::SourceHandler::Base for details on how to implement a source handler
  # class.
  module SourceHandler

    autoload :Base, 'webgen/sourcehandler/base'
    autoload :Copy, 'webgen/sourcehandler/copy'
    autoload :Directory, 'webgen/sourcehandler/directory'
    autoload :Metainfo, 'webgen/sourcehandler/metainfo'
    autoload :Template, 'webgen/sourcehandler/template'
    autoload :Page, 'webgen/sourcehandler/page'
    autoload :Fragment, 'webgen/sourcehandler/fragment'
    autoload :Virtual, 'webgen/sourcehandler/virtual'

    # This class is used by Website to do the actual rendering of the website. It
    #
    # * collects all source paths using the source classes
    # * creates nodes using the source handler classes
    # * writes changed nodes out using an output class
    class Main

      include WebsiteAccess
      include Loggable

      def initialize #:nodoc:
        website.blackboard.add_service(:create_nodes, method(:create_nodes))
        website.blackboard.add_service(:source_paths, method(:find_all_source_paths))
        website.blackboard.add_listener(:node_meta_info_changed?, method(:meta_info_changed?))
      end

      # Render the nodes provided in the +tree+. Before the actual rendering is done, the sources
      # are checked (nodes for deleted sources are deleted, nodes for new and changed sources).
      def render(tree)
        # Add new and changed nodes, remove nodes of deleted paths
        puts "Generating tree..."
        time = Benchmark.measure do
          used_paths = Set.new
          paths = Set.new([nil])
          while paths.length > 0
            used_paths += (paths = Set.new(find_all_source_paths.keys) - used_paths - clean(tree))
            create_nodes_from_paths(tree, paths)
            website.cache.reset_volatile_cache
          end
        end
        puts "...done in " + ('%2.4f' % time.real) + ' seconds'

        output = website.blackboard.invoke(:output_instance)

        puts "Writing changed nodes..."
        time = Benchmark.measure do
          tree.node_access[:alcn].sort.each do |name, node|
            node.dirty_meta_info = node.created = false
            next if node == tree.dummy_root || !node.dirty
            node.dirty = false

            begin
              if !node['no_output'] && (content = node.content)
                puts " "*4 + name, :verbose
                type = if node.is_directory?
                         :directory
                       elsif node.is_fragment?
                         :fragment
                       else
                         :file
                       end
                output.write(node.path, content, type)
              end
            rescue
              raise RuntimeError, "Error while processing <#{node.absolute_lcn}>: #{$!.message}", $!.backtrace
            end
          end
        end
        puts "...done in " + ('%2.4f' % time.real) + ' seconds'
      end

      #######
      private
      #######

      # Return a hash with all source paths.
      def find_all_source_paths
        if !defined?(@paths)
          source = Webgen::Source::Stacked.new(website.config['sources'].collect do |mp, name, *args|
                                                 [mp, constant(name).new(*args)]
                                               end)
          @paths = {}
          source.paths.each do |path|
            if !(website.config['sourcehandler.ignore'].any? {|pat| File.fnmatch(pat, path, File::FNM_CASEFOLD|File::FNM_DOTMATCH)})
              @paths[path.path] = path
            end
          end
        end
        @paths
      end

      # Return only the subset of +paths+ which are handled by the source handler +name+.
      def paths_for_handler(name, paths)
        patterns = website.config['sourcehandler.patterns'][name]
        return [] if patterns.nil?

        options = (website.config['sourcehandler.casefold'] ? File::FNM_CASEFOLD : 0) |
          (website.config['sourcehandler.use_hidden_files'] ? File::FNM_DOTMATCH : 0)
        find_all_source_paths.values_at(*paths).select do |path|
          patterns.any? {|pat| File.fnmatch(pat, path, options)}
        end
      end

      # Use the source handlers to create nodes for the +paths+ in the +tree+.
      def create_nodes_from_paths(tree, paths)
        website.config['sourcehandler.invoke'].sort.each do |priority, shns|
          shns.each do |shn|
            sh = website.cache.instance(shn)
            paths_for_handler(shn, paths).sort.each do |path|
              parent_dir = path.directory.split('/').collect {|p| Path.new(p).cn}.join('/')
              parent_dir += '/' if path != '/' && parent_dir == ''
              create_nodes(tree, parent_dir, path, sh)
            end
          end
        end
      end

      # Prepare everything to create nodes under the absolute lcn path +parent_path_name+ in the
      # +tree from the +path+ using the +source_handler+. If a block is given, the actual creation
      # of the nodes is deferred to it. After the nodes are created, it is also checked if they have
      # all needed properties.
      def create_nodes(tree, parent_path_name, path, source_handler) #:yields: parent, path
        if !(parent = tree[parent_path_name])
          raise "The specified parent path <#{parent_path_name}> does not exist"
        end
        path = path.dup
        path.meta_info = default_meta_info(path, source_handler.class.name)
        (website.cache[:sourcehandler_path_mi] ||= {})[[path.path, source_handler.class.name]] = path.meta_info.dup
        website.blackboard.dispatch_msg(:before_node_created, parent, path)
        *nodes = if block_given?
                   yield(parent, path)
                 else
                   source_handler.create_node(parent, path.dup)
                 end
        nodes.compact.each do |node|
          website.blackboard.dispatch_msg(:after_node_created, node)
        end
        nodes
      end

      # Return the default meta info for the pair of +path+ and +sh_name+.
      def default_meta_info(path, sh_name)
        path.meta_info.merge(website.config['sourcehandler.default_meta_info'][:all]).
          merge(website.config['sourcehandler.default_meta_info'][sh_name] || {})
      end

      # Check if the default meta information for +node+ has changed since the last run.
      def meta_info_changed?(node)
        path = node.node_info[:src]
        cached_mi = website.cache[:sourcehandler_path_mi][[path, node.node_info[:processor]]]
        if !cached_mi || cached_mi != default_meta_info(@paths[path], node.node_info[:processor])
          node.dirty_meta_info = true
        end
      end

      # Clean the +tree+ by deleting nodes which have changed or which don't have an associated
      # source anymore. Return all paths for which nodes need to be created.
      def clean(tree)
        paths_to_delete = Set.new
        paths_not_to_delete = Set.new
        nodes_to_be_deleted = Set.new
        tree.node_access[:alcn].each do |alcn, node|
          next if node == tree.dummy_root || tree[alcn].nil?

          deleted = !find_all_source_paths.include?(node.node_info[:src])
          if !node.created && (deleted ||
                               find_all_source_paths[node.node_info[:src]].changed? ||
                               node.changed?)
            paths_not_to_delete << node.node_info[:src]
            nodes_to_be_deleted << [node, deleted]
          else
            paths_to_delete << node.node_info[:src]
          end
        end

        nodes_to_be_deleted.each {|node, deleted| tree.delete_node(node, deleted)}
        #TODO: delete output path

        # source paths that should be used
        paths_to_delete - paths_not_to_delete
      end

    end

  end

end
