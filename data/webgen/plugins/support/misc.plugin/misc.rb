module Support

  # This plugin provides miscellaneous methods for use by other plugins. It's the place where all
  # those methods are defined that fit nowhere else.
  class Misc

    # Returns a hash (key=plugin name, value=plugin object) containing all available content
    # processors.
    def content_processors
      if !defined?( @processors ) || @cached_plugins_hash != @plugin_manager.plugin_infos.keys.hash
        @processors = {}
        @plugin_manager.plugin_infos[/^ContentProcessor\//].each do |k,v|
          @processors[v['processes']] = @plugin_manager[k] unless @plugin_manager[k].nil?
        end
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

  end

end
