# -*- encoding: utf-8 -*-

require 'set'
require 'webgen/extension_manager'

module Webgen

  # Namespace for all item trackers.
  #
  # == About
  #
  # This extension manager class is used to track various "items". Such items can be added as a
  # dependency to a node and later be checked if they have changed. This allows webgen to
  # conditionally render a node.
  #
  # An item can basically be anything, there only has to be an item tracker extension that knows how
  # to handle it. Each item tracker extension is uniquely identified by its name (e.g.
  # :+node_content+, :+node_meta_info+, ...).
  #
  # == Implementing an item tracker.
  #
  # An item tracker extension class must respond to the following methods:
  #
  # [initialize(website)]
  #   Initializes the extension and provides the website object which can be used to resolve the
  #   item ID to the referenced item or item data itself.
  #
  # [item_id(*item)]
  #   Return the unique ID for the given item. The returned ID has to be unique for this item
  #   tracker extension
  #
  # [item_data(*item)]
  #   Return the data for the item so that it can be correctly checked later if it has changed. If
  #   data for the given item cannot be computer anymore because the item got invalid, raise an
  #   exception.
  #
  # [item_changed?(item_id, old_data)]
  #   Return +true+ if the item identified by its unique ID has changed. The parameter +old_data+
  #   contains the last known data of the item.
  #
  # [node_referenced?(item_id, old_data, node_alcn)]
  #   Return +true+ if the node identified by +node_alcn+ is referenced in the old data identified
  #   by the unique ID.
  #
  # [item_description(item_id, data)]
  #   Return a string or an array of strings which describe the item (identified by its unique ID)
  #   and the given item data. This is used for display purposes and should therefore include a
  #   nice, human readable interpretation of the item.
  #
  # The parameter +item+ for the methods +item_id+ and +item_data+ contains the information needed
  # to identify the item and is depdendent on the specific item tracker extension class. Therefore
  # you need to look at the documentation for an item tracker extension to see what it expects as
  # the item.
  #
  # Since these methods are invoked multiple times for different items, these methods should have no
  # side effects.
  #
  # == Sample item tracker
  #
  # The following sample item tracker tracks changes in configuration values. It needs the
  # configuration option name as item.
  #
  #   class ConfigTracker
  #
  #     def initialize(website)
  #       @website = website
  #     end
  #
  #     def item_id(config_key)
  #       config_key
  #     end
  #
  #     def item_data(config_key)
  #       @website.config[config_key]
  #     end
  #
  #     def item_changed?(config_key, old_val)
  #       @website.config[config_key] != old_val
  #     end
  #
  #     def node_referenced?(config_key, config_value, node_alcn)
  #       false
  #     end
  #
  #     def item_description(config_key, old_val)
  #       "The website configuration option '#{config_key}'"
  #     end
  #
  #   end
  #
  #   website.ext.item_tracker.register ConfigTracker, name: :config
  #
  class ItemTracker

    include Webgen::ExtensionManager

    # Create a new item tracker for the given website.
    def initialize(website)
      super()
      @instances = {}
      @node_dependencies = Hash.new {|h,k| h[k] = Set.new}
      @item_data = {}
      @cached = {:node_dependencies => {}, :item_data => {}}
      @written_nodes = []
      @checked_nodes = Set.new

      @website = website

      @item_changed = {}

      @website.blackboard.add_listener(:website_initialized, 'item_tracker') do
        @cached = @website.cache[:item_tracker_data] || @cached
      end

      @website.blackboard.add_listener(:after_tree_populated, 'item_tracker') do |node|
        @item_data.keys.each do |uid|
          @item_data[uid] = item_tracker(uid.first).item_data(*uid.last)
        end
      end

      @website.blackboard.add_listener(:before_all_nodes_written, 'item_tracker') do
        # make all used item data from the previous pass current again if applicable and remove
        # invalid UIDs
        uids_to_update = @written_nodes.each_with_object(Set.new) do |node, set|
          next unless @website.tree[node.alcn]
          set.merge(@node_dependencies[node.alcn])
        end
        uids_to_update.each do |uid|
          begin
            @item_data[uid] = item_tracker(uid.first).item_data(*uid.last)
          rescue Exception
            @item_data.delete(uid)
            @cached[:item_data].delete(uid)
            @written_nodes.each do |node|
              if @node_dependencies[node.alcn].include?(uid)
                @node_dependencies[node.alcn].delete(uid)
                @cached[:node_dependencies][node.alcn].delete(uid)
                node.node_info[:item_tracker_changed_once] = true
              end
            end
          end
        end

        @written_nodes = []
        @item_changed = {}
      end

      @website.blackboard.add_listener(:after_node_written, 'item_tracker') do |node|
        @written_nodes << node
      end

      @website.blackboard.add_listener(:after_all_nodes_written, 'item_tracker') do
        # update cached data with data from the run
        uids_to_update = Set.new
        @written_nodes.each do |node|
          next unless @website.tree[node.alcn]
          node.node_info.delete(:item_tracker_changed_once)
          @cached[:node_dependencies][node.alcn] = @node_dependencies[node.alcn]
          uids_to_update.merge(@node_dependencies[node.alcn])
        end
        uids_to_update.each {|uid| @cached[:item_data][uid] = @item_data[uid]}
      end

      @website.blackboard.add_listener(:website_generated, 'item_tracker') do
        @cached[:node_dependencies].reject! {|alcn, data| !@website.tree[alcn]}

        used_uids = @cached[:node_dependencies].each_with_object(Set.new) {|(_, uids), obj| obj.merge(uids)}
        @cached[:item_data].merge!(@item_data)
        @cached[:item_data].reject! {|uid, _| !used_uids.include?(uid)}

        @website.cache[:item_tracker_data] = @cached
      end
    end

    # Register an item tracker.
    #
    # The parameter +klass+ has to contain the name of the item tracker class or the class object
    # itself. If the class is located under this namespace, only the class name without the
    # hierarchy part is needed, otherwise the full class name including parent module/class names is
    # needed.
    #
    # === Options:
    #
    # [:name] The name for the item tracker class. If not set, it defaults to the snake-case version
    #         (i.e. FileSystem → file_system) of the class name (without the hierarchy part). It
    #         should only contain letters.
    #
    # === Examples:
    #
    #   item_tracker.register('Node')   # registers Webgen::ItemTracker::Node
    #
    #   item_tracker.register('::Node') # registers Node !!!
    #
    #   item_tracker.register('MyModule::Doit', name: 'infos')
    #
    def register(klass, options={}, &block)
      do_register(klass, options, false, &block)
    end

    # Add the given item that is handled by the item tracker extension +name+ as a dependency to the
    # node.
    def add(node, name, *item)
      uid = unique_id(name, item)
      @node_dependencies[node.alcn] << uid
      @item_data[uid] ||= item_tracker(name).item_data(*uid.last)
    end

    # Return +true+ if the given node has changed.
    def node_changed?(node)
      return false if @checked_nodes.include?(node)
      @checked_nodes << node
      node.node_info[:item_tracker_changed_once] ||
        !@cached[:node_dependencies].has_key?(node.alcn) ||
        @cached[:node_dependencies][node.alcn].any? {|uid| item_changed_by_uid?(uid)}
    ensure
      @checked_nodes.delete(node)
    end

    # Return +true+ if the given node has been referenced by any item tracker extension.
    def node_referenced?(node)
      if (cached = @website.cache.volatile[:item_tracker_referenced_nodes]).nil?
        cached = @website.cache.volatile[:item_tracker_referenced_nodes] = Set.new
        @cached[:node_dependencies].each do |alcn, uids|
          uids.each do |uid|
            cached.merge(item_tracker(uid.first).referenced_nodes(uid.last, @cached[:item_data][uid]) - [alcn])
          end
        end
      end

      cached.include?(node.alcn)
    end

    # Return +true+ if the given item that is handled by the item tracker extension +name+ has
    # changed.
    def item_changed?(name, *item)
      item_changed_by_uid?(unique_id(name, item))
    end

    # Return a hash with mappings from node ALCNs to their used items (items are converted to
    # a human readable representation by using the #item_description method).
    #
    # If the parameter +include_default+ is set to +false+, the default items added to each node so
    # that it is possible to correctly detect changes, are not included.
    #
    # The cached data, not the current data, is used. So this information is only useful after a
    # website has been generated.
    def cached_items(include_default=true)
      @cached[:node_dependencies].each_with_object({}) do |(alcn, uids), h|
        h[alcn] = uids.sort {|a,b| a.first <=> b.first }.map do |uid|
          next if !include_default && ((uid.first == :node_meta_info && uid.last.first == alcn )||
                                       (uid.first == :node_content && uid.last == alcn))
          item_tracker(uid.first).item_description(uid.last, @cached[:item_data][uid])
        end.compact
      end
    end

    #######
    private
    #######

    # Return +true+ if the given item has changed. See #add for a description of the item
    # parameters.
    def item_changed_by_uid?(uid)
      return @item_changed[uid] if @item_changed.has_key?(uid)
      @item_changed[uid] = if !@cached[:item_data].has_key?(uid)
                             true
                           else
                             item_tracker(uid.first).item_changed?(uid.last, @cached[:item_data][uid])
                           end
    end

    # Return the unique ID for the given item handled by the item tracker extension object specified
    # by name.
    def unique_id(name, item)
      [name.to_sym, item_tracker(name).item_id(*item)]
    end

    # Return the item tracker extension object called name.
    def item_tracker(name)
      @instances[name] ||= extension(name).new(@website)
    end

  end

end
