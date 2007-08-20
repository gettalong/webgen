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

    # Normalizes the +used_nodes+ hash, using +node+ as reference where needed, sothat it can be
    # correctly stored in the cache.
    #
    # The +used_nodes+ hash is assumed to have the following structure:
    # <tt>used_nodes[:nodes]</tt>:: an array of nodes of which the content has been used
    # <tt>used_nodes[:node_infos]</tt>:: an array of nodes of which the meta information
    #                                    has been used
    #
    # The +used_nodes+ hash is changed in-place and can then be used in the #used_nodes_changed?
    # method.
    def normalize_used_nodes( used_nodes, node )
      used_nodes[:nodes] = (used_nodes[:nodes] || []).compact.uniq.select {|n| n != node}.collect {|n| n.absolute_lcn}
      used_nodes[:node_infos] = (used_nodes[:node_infos] || []).compact.uniq.collect! {|n| n.absolute_lcn}
    end

    # Uses a normalized +used_nodes+ hash (see #normalize_used_nodes) and checks if any node or node
    # meta information has changed.
    def used_nodes_changed?( used_nodes, node )
      fh = @plugin_manager['Core/FileHandler']
      cm = @plugin_manager['Core/CacheManager']
      if used_nodes
        used_nodes[:nodes].any? {|p| n = cm.node_for_path( node, p ); n.nil? || fh.node_changed?( n ) } ||
          used_nodes[:node_infos].any? {|p| n = cm.node_for_path( node, p ); n.nil? || fh.meta_info_changed?( n ) }
      else
        true
      end
    end

  end

end
