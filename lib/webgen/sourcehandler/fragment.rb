require 'webgen/sourcehandler/base'
require 'webgen/websiteaccess'

module Webgen::SourceHandler

  # Handles page fragment nodes and provides utility methods for parsing HTML headers and generating
  # fragment nodes from them.
  class Fragment

    include Base
    include Webgen::WebsiteAccess

    HTML_HEADER_REGEXP = /<h([123456])(?:>|\s([^>]*)>)(.*?)<\/h\1\s*>/i
    HTML_ATTR_REGEXP = /\s*(\w+)\s*=\s*('|")([^\2]+)\2\s*/

    # Parses the String +content+ for headers +h1+, ..., +h6+ but only uses those headers which have
    # an +id+ attribute. Then it generates a list of arrays with entries <tt>level, id, title, sub
    # sections</tt> where <tt>sub sections</tt> is such a list again.
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

    # Creates nested fragment nodes under +parent+ from +sections+ (which can be created using
    # +parse_html_headers+). The meta information +in_menu+ of the fragment nodes is set to the
    # parameter +in_menu+ and the meta info +sort_info+ is calculated from the base +si+ value.
    def create_fragment_nodes(sections, parent, in_menu, si = 1000 )
      sections.each do |level, id, title, sub_sections|
        node = website.blackboard.invoke(:create_nodes, parent.tree, parent.absolute_lcn,
                                         Webgen::Path.new('#' + id), self).first
        node['title'] = title
        node['in_menu'] = in_menu
        node['sort_info'] = si = si.succ
        node.node_info[:src] = parent.node_info[:src]
        create_fragment_nodes(sub_sections, node, in_menu, si.succ)
      end
    end

  end

end
