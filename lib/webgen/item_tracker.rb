# -*- encoding: utf-8 -*-

require 'set'
require 'webgen/common'

module Webgen

  # Namespace for all item trackers.
  #
  # == About this class
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
  # An item tracker extension class must respond to the following four methods:
  #
  # [<tt>initialize(website)</tt>]
  #   Initializes the extension and provides the website object which can be used to resolve the
  #   item ID to the referenced item or item data itself.
  #
  # [<tt>item_id(*item)</tt>]
  #   Return the unique ID for the given item. The returned ID has to be unique for this item
  #   tracker extension
  #
  # [<tt>item_data(*item)</tt>]
  #   Return the data for the item so that it can be correctly checked later if it has changed.
  #
  # [<tt>changed?(item_id, old_data)</tt>]
  #   Return +true+ if the item identified by its unique ID has changed. The parameter +old_data+
  #   contains the last known data of the item.
  #
  # [<tt>node_referenced?(item_id, node_alcn)</tt>]
  #   Return +true+ if the node identified by +node_alcn+ is referenced in the item identified by
  #   its unique ID.
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
  #     def changed?(config_key, old_val)
  #       @website.config[config_key] != old_val
  #     end
  #
  #     def node_referenced?(config_key, node_alcn)
  #       false
  #     end
  #
  #   end
  #
  #   website.ext.item_tracker.register ConfigTracker, name: :config
  #
  class ItemTracker

    include Webgen::Common::ExtensionManager

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

      @website.blackboard.add_listener(:website_initialized, self) do
        @cached = @website.cache[:item_tracker_data] || @cached
      end

      @website.blackboard.add_listener(:after_tree_populated, self) do |node|
        @item_data.keys.each do |uid|
          @item_data[uid] = item_tracker(uid.first).item_data(*uid.last)
        end
      end

      @website.blackboard.add_listener(:after_node_written, self) do |node|
        @written_nodes << node
      end

      @website.blackboard.add_listener(:after_all_nodes_written, self) do
        # update cached data with data from the run
        @written_nodes.each do |node|
          @cached[:node_dependencies][node.alcn] = @node_dependencies[node.alcn]
          @node_dependencies[node.alcn].each {|uid| @cached[:item_data][uid] = @item_data[uid]}
        end
        # make all used item data current again
        @written_nodes.each do |node|
          @node_dependencies[node.alcn].each do |uid|
            @item_data[uid] = item_tracker(uid.first).item_data(*uid.last)
          end
        end
        @written_nodes = []
      end

      @website.blackboard.add_listener(:website_generated, self) do
        @cached[:node_dependencies].reject! {|alcn, data| !@website.tree[alcn]}
        @cached[:item_data].merge!(@item_data)
        @cached[:item_data].reject! do |uid, _|
          !@cached[:node_dependencies].find {|alcn, data| data.include?(uid)}
        end
        @website.cache[:item_tracker_data] = @cached
      end
    end

    # Register an item tracker. The parameter +klass+ has to contain the name of the item tracker
    # class. If the class is located under this namespace, only the class name without the hierarchy
    # part is needed, otherwise the full class name including parent module/class names is needed.
    #
    # === Options:
    #
    # [:name] The name for the item tracker class. If not set, it defaults to the snake-case version
    #         (i.e. FileSystem → file_system) of the class name (without the hierarchy part). It
    #         should only contain letters.
    #
    # [:author] The author of the item tracker class.
    #
    # [:summary] A short description of the item tracker class.
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
      @item_data[uid] = item_tracker(name).item_data(*uid.last)
    end

    # Return +true+ if the given node has changed.
    def node_changed?(node)
      return false if @checked_nodes.include?(node)
      @checked_nodes << node
      !@cached[:node_dependencies].has_key?(node.alcn) ||
        @cached[:node_dependencies][node.alcn].any? {|uid| item_changed?(uid)}
    ensure
      @checked_nodes.delete(node)
    end

    # Return +true+ if the given node has been referenced by any item tracker extension.
    def node_referenced?(node)
      alcn = node.alcn
      @cached[:item_data].any? do |uid, data|
        next if @cached[:node_dependencies][alcn] && @cached[:node_dependencies][alcn].include?(uid)
        item_tracker(uid.first).node_referenced?(uid.last, alcn)
      end
    end

    #######
    private
    #######

    # Return +true+ if the given item has changed. See #add for a description of the item
    # parameters.
    def item_changed?(uid)
      if !@cached[:item_data].has_key?(uid)
        true
      else
        item_tracker(uid.first).changed?(uid.last, @cached[:item_data][uid]) #TODO: probably cache this result
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
