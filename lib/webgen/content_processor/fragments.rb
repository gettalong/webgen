# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
require 'webgen/path'

module Webgen
  class ContentProcessor

    # Uses the HTML headers h1, h2, ..., h6 to generate nested fragment nodes.
    module Fragments

      # Create the nested fragment nodes from the content under the content node but only if there
      # is no associated block or the block is named +content+.
      def self.call(context)
        if !context[:block_name] || context[:block_name] == 'content'
          sections = parse_html_headers(context.content)
          create_fragment_nodes(context, sections, context.content_node)
        end
        context
      end

      HTML_HEADER_REGEXP = /<h([123456])(?:>|\s([^>]*)>)(.*?)<\/h\1\s*>/i
      HTML_ATTR_REGEXP = /\s*(\w+)\s*=\s*('|")(.+?)\2\s*/

      # Parse the string +content+ for headers +h1+, ..., +h6+ and return the found, nested
      # sections.
      #
      # Only those headers are used which have an +id+ attribute set. The method returns a list of
      # arrays with entries <tt>level, id, title, sub sections</tt> where <tt>sub sections</tt> is
      # such a list again.
      def self.parse_html_headers(content)
        sections = []
        stack = []
        content.scan(HTML_HEADER_REGEXP).each do |level,attrs,title|
          next if attrs.nil?
          id_attr = attrs.scan(HTML_ATTR_REGEXP).find {|name,sep,value| name == 'id'}
          next if id_attr.nil?
          id = id_attr[2]

          section = [level.to_i, id, title, []]
          success = false
          while !success
            if stack.empty?
              sections << section
              stack << section
              success = true
            elsif stack.last.first < section.first
              stack.last.last << section
              stack << section
              success = true
            else
              stack.pop
            end
          end
        end
        sections
      end

      # Create nested fragment nodes under +parent+ from +sections+ (which can be created using
      # #parse_html_headers).
      #
      # The meta info +sort_info+ is calculated from the base +si+ value.
      def self.create_fragment_nodes(context, sections, parent, si = 1000)
        sections.each do |level, id, title, sub_sections|
          path = Webgen::Path.new(parent.alcn.sub(/#.*$/, '') + '#' + id)
          path.meta_info['parent_alcn'] = parent.alcn
          path.meta_info['pipeline'] = []
          path.meta_info['no_output'] = true
          path.meta_info['title'] = title
          path.meta_info['sort_info'] = si = si.succ
          node = context.website.ext.path_handler.create_secondary_nodes(path, '', 'copy', context.content_node.alcn).first

          create_fragment_nodes(context, sub_sections, node, si.succ)
        end
      end

    end

  end
end
