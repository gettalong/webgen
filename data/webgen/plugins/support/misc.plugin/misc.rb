module Support

  # This plugin provides miscellaneous methods for use by other plugins. It's the place where all
  # those methods are defined that fit nowhere else.
  class Misc

    # Helper class managing access to content processors. Uses lazy evaluation to only instantiate
    # processors that are really used.
    class ProcessorProxy

      def initialize( plugin_manager )
        @plugin_manager = plugin_manager
        @processors = {}
        @plugin_manager.plugin_infos[/^ContentProcessor\//].each do |k,v|
          @processors[v['processes']] = k
        end
      end

      def keys
        @processors.keys
      end

      # Check if given +processor+ is available
      def has_key?( processor )
        !@plugin_manager[@processors[processor]].nil?
      end

      # Return the +processor+.
      def []( processor )
        @plugin_manager[@processors[processor]]
      end

    end

    # Returns a hash (key=plugin name, value=plugin object) containing all available content
    # processors.
    def content_processors
      if !defined?( @processors ) || @cached_plugins_hash != @plugin_manager.plugin_infos.keys.hash
        @processors = ProcessorProxy.new( @plugin_manager )
        @cached_plugins_hash = @plugin_manager.plugin_infos.keys.hash
      end
      @processors
    end

    # Takes an array +node_lcns+ of absolute LCNs and checks if the corresponding nodes have
    # changed. The +node+ is used for finding the specified nodes. Also, if an absolute LCN maps to
    # +node+, it is not checked if it has changed.
    def nodes_changed?( node_lcns, node )
      fh = @plugin_manager['Core/FileHandler']
      cm = @plugin_manager['Core/CacheManager']
      node_lcns.any? {|p| n = cm.node_for_path( node, p ); n.nil? || (n != node && fh.node_changed?( n )) }
    end

    # Takes an array +node_lcns+ of absolute LCNs and checks if the corresponding node meta
    # informations have changed. The +node+ is used for finding the specified nodes. Also, if an
    # absolute LCN maps to +node+, it is not checked.
    def nodes_meta_info_changed?( node_lcns, node )
      fh = @plugin_manager['Core/FileHandler']
      cm = @plugin_manager['Core/CacheManager']
      node_lcns.any? {|p| n = cm.node_for_path( node, p ); n.nil? || (n != node && fh.meta_info_changed?( n )) }
    end

  end

end
