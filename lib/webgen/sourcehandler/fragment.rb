# -*- encoding: utf-8 -*-

module Webgen::SourceHandler

  # Handles page fragment nodes and provides utility methods for parsing HTML headers and generating
  # fragment nodes from them.
  class Fragment

    include Base
    include Webgen::WebsiteAccess

    HTML_HEADER_REGEXP = /<h([123456])(?:>|\s([^>]*)>)(.*?)<\/h\1\s*>/i
    HTML_ATTR_REGEXP = /\s*(\w+)\s*=\s*('|")(.+?)\2\s*/

    # Parse the string +content+ for headers +h1+, ..., +h6+ and return the found, nested sections.
    #
    # Only those headers are used which have an +id+ attribute set. The method returns a list of
    # arrays with entries <tt>level, id, title, sub sections</tt> where <tt>sub sections</tt> is
    # such a list again.
    def parse_html_headers(content)
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
    # +parse_html_headers+). +path+ is the source path that defines the fragments (which is not the
    # same as the creation path for +parent+). The meta information +in_menu+ of the fragment nodes
    # is set to the parameter +in_menu+ and the meta info +sort_info+ is calculated from the base
    # +si+ value.
    def create_fragment_nodes(sections, parent, path, in_menu, si = 1000)
      sections.each do |level, id, title, sub_sections|
        fragment_path = parent.alcn.sub(/#.*$/, '') + '#' + id
        node = website.blackboard.invoke(:create_nodes,
                                         Webgen::Path.new(fragment_path, path.source_path),
                                         self) do |cn_path|
          cn_path.meta_info['title'] = title
          cn_path.meta_info['in_menu'] = in_menu
          cn_path.meta_info['sort_info'] = si = si.succ
          create_node(cn_path, :parent => parent)
        end.first
        create_fragment_nodes(sub_sections, node, path, in_menu, si.succ)
      end
    end

  end

end
