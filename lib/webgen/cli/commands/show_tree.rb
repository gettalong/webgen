# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for showing the node tree.
    class ShowTreeCommand < CmdParse::Command

      def initialize # :nodoc:
        super('tree', takes_commands: false)
        short_desc('Show the node tree')
        long_desc(<<DESC)
Shows the internal representation of all destination paths that have been created
from the source paths. Additionally, the meta information associated with each
node can be shown as well.

This command can be used before or after the website has been generated. Note,
however, that nodes that are created during generation like fragment nodes can
only be shown if the website has been generated.

Due to the way webgen works this command may take some time before actually
showing the tree because it has to be built first.

If an argument is given, only those nodes that have the argument in their LCN
are displayed.

Hint: The global verbosity option enables additional output.
DESC
        options do |opts|
          opts.on("-a", "--alcn", "Use ALCN insted of LCN for paths") do |v|
            @use_alcn = true
          end
          opts.on("-f", "--[no-]fragments", "Show fragment nodes (default: no)") do |v|
            @show_fragments = v
          end
          opts.on("-m", "--[no-]meta-info", "Show meta information (default: no)") do |v|
            @meta_info = v
          end
        end
        @meta_info = false
        @use_alcn = false
        @show_fragments = false
      end

      def execute(selector = nil) # :nodoc:
        command_parser.website.ext.path_handler.populate_tree
        data = collect_data(command_parser.website.tree.dummy_root.children, selector)
        print_tree(data, selector)
      end

      def collect_data(children, selector)
        children.sort {|a,b| a.alcn <=> b.alcn}.map do |node|
          sub = collect_data(node.children, selector)
          if sub.length > 0 ||
              ((selector.nil? || node.alcn.include?(selector)) &&
               ((!node.is_fragment? || @show_fragments) &&
                (!node['passive'] || command_parser.website.ext.item_tracker.node_referenced?(node))))
            data = [@use_alcn ? node.alcn : node.lcn]
            data << node.alcn
            data << (@meta_info ? node.meta_info.map {|k,v| "#{k}: #{v.inspect}"} : [])
            data << sub
            data
          else
            nil
          end
        end.compact
      end
      private :collect_data

      def print_tree(data, indent = '', selector)
        data.each do |name, alcn, info, children|
          puts("#{indent}#{Utils.light(Utils.blue(name))}")
          info.each {|i| puts("#{indent}  #{i}")} if info.length > 0 && (selector.nil? || alcn.include?(selector))
          print_tree(children, indent + '  ', selector)
        end
      end
      private :print_tree

    end

  end
end
