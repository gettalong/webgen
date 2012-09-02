# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for showing dependencies (tracked items) of paths.
    class ShowDependenciesCommand < CmdParse::Command

      def initialize # :nodoc:
        super('deps', false, false, true)
        self.short_desc = 'Show dependencies for all paths'
        self.description = Utils.format_command_desc(<<DESC)
Shows the dependencies (i.e. tracked items) for each path. This is only useful
after webgen has generated the website at least once so that this information
is available.

If an argument is given, only those paths that have the argument in their name
are displayed with their dependencies.

Hint: The global verbosity option enables additional output.
DESC
      end

      def execute(args)
        cache = commandparser.website.cache[:item_tracker_data]
        if cache.nil?
          puts "No data available, you need to generate the website first!"
          return
        end

        cache[:node_dependencies].sort.each do |alcn, deps|
          deps = deps.sort {|a,b| a.first <=> b.first }.map do |uid|
            method = "format_#{uid.first}"
            if respond_to?(method, true)
              send(method, alcn, uid, cache[:item_data][uid])
            else
              unknown_uid(uid)
            end
          end.compact

          if deps.length > 0 || commandparser.verbose
            puts("#{Utils.light(Utils.blue(alcn))}: ")
            deps.each {|d| puts("  #{[d].flatten.join("\n    ")}")}
          end
        end
      end

      def unknown_uid(uid)
        uid.first.to_s
      end
      private :unknown_uid

      def format_node_meta_info(alcn, uid, data)
        dep_alcn, key = *uid.last
        return if alcn == dep_alcn && !commandparser.verbose

        if key.nil?
          "Any meta info from <#{dep_alcn}>"
        else
          "Meta info key '#{key}' from <#{dep_alcn}>"
        end
      end
      private :format_node_meta_info

      def format_node_content(alcn, uid, data)
        dep_alcn = uid.last
        return if alcn == dep_alcn && !commandparser.verbose

        "Content from node <#{dep_alcn}>"
      end
      private :format_node_content

      def format_file(alcn, uid, data)
        "Content from file '#{uid.last}'"
      end
      private :format_file

      def format_missing_node(alcn, uid, data)
        path, lang = *uid.last

        "Missing acn, alcn or dest path <#{path}>" << (lang.nil? ? '' : " in language '#{lang}'")
      end
      private :format_missing_node

      def format_nodes(alcn, uid, data)
        method, options, type = *uid.last

        res = [(type == :content ? "Content" : "Meta info") + " from these nodes"]
        res.first << " (result of #{[method].flatten.join('.')})" if commandparser.verbose
        res.first << ":"
        res += data.flatten
      end
      private :format_nodes

    end

  end
end
