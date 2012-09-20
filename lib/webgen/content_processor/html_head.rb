# -*- encoding: utf-8 -*-

require 'erb'

module Webgen
  class ContentProcessor

    # == General information
    #
    # Inserts additional links to CSS/JS files and other HTML head meta info directly before the
    # HTML head end tag.
    #
    # The data used by this content processor is taken from the Context object. Therefore this
    # processor should be the last in the processing pipeline so that all other processors have been
    # able to set the data.
    #
    # Use the methods defined on the special Context#html_head object to provide values.
    #
    # == Internal details
    #
    # The key ':cp_html_head' of 'context.persistent' is used (the normal 'context.options' won't do
    # because the data needs to be shared 'backwards' during the rendering) and it has to be a Hash
    # with the following values:
    #
    # [:js_file] An array of already resolved relative or absolute paths to Javascript files.
    # [:js_inline] An array of Javascript fragments to be inserted directly into the head section.
    # [:css_file] An array of already resolved relative or absolute paths to CSS files.
    # [:css_inline] An array of CSS fragments to be inserted directly into the head section.
    # [:meta] A hash with key-value pairs from which 'meta' tags are generated. The keys and the
    #         values will be properly escaped before insertion. The entries in the meta information
    #         'meta' of the content node are also used and take precedence over these entries.
    #
    # Duplicate values will be removed from the above mentioned arrays before generating the output.
    #
    module HtmlHead

      HTML_HEAD_END_RE = /<\/head\s*>/i #:nodoc:

      # Insert the additional header information.
      def self.call(context)
        context.content.sub!(HTML_HEAD_END_RE) do |match|
          result = ''
          result << tags_from_context_data(context)
          result << links_to_translations(context)
          result << links_from_link_meta_info(context)
          result << match
        end
        context
      end

      # Return a string containing the HTML tags corresponding to the information set in the given
      # Context object and the values of the meta info key +meta+ of the content node.
      def self.tags_from_context_data(context)
        result = ''
        if context.persistent[:cp_html_head].kind_of?(Hash)
          process_data_array(context, :js_file) do |js_file|
            result += "\n<script type=\"text/javascript\" src=\"#{js_file}\"></script>"
          end

          process_data_array(context, :js_inline) do |content|
            result += "\n<script type=\"text/javascript\">//<![CDATA[\n#{content}\n//]]></script>"
          end

          process_data_array(context, :css_file) do |css_file|
            result += "\n<link rel=\"stylesheet\" href=\"#{css_file}\" type=\"text/css\"/>"
          end

          process_data_array(context, :css_inline) do |content|
            result += "\n<style type=\"text/css\">/*<![CDATA[/*/\n#{content}\n/*]]>*/</style>"
          end

          (context.persistent[:cp_html_head][:meta] || {}).merge(context.content_node['meta'] || {}).each do |name, content|
            result += "\n<meta name=\"#{ERB::Util.h(name)}\" content=\"#{ERB::Util.h(content)}\" />"
          end
        end
        result
      end

      # Yield the values of the specified array.
      def self.process_data_array(context, array_name, &block)
        (context.persistent[:cp_html_head][array_name] || []).uniq.each(&block)
      end

      # Return a string containing HTML link tags to translations of the destination node.
      def self.links_to_translations(context)
        context.website.tree.translations(context.dest_node).map do |node|
          next '' if node.alcn == context.dest_node.alcn
          context.website.ext.item_tracker.add(context.dest_node, :node_meta_info, node.alcn)

          result = "\n<link type=\"text/html\" rel=\"alternate\" hreflang=\"#{node.lang}\" "
          result << "href=\"#{context.dest_node.route_to(node)}\" "
          if node['title'] && !node['title'].empty?
            result << "lang=\"#{node.lang}\" title=\"#{ERB::Util.h(node['title'])}\" "
          end
          result << "/>"
        end.join('')
      end

      # Given an array of path names, add tracker information for the resolved nodes (reference node
      # is the content node) and return the relative paths to them.
      def self.resolve_paths(context, paths)
        [paths].flatten.compact.collect do |path|
          next path if Webgen::Path.url(path, false).absolute?
          node = context.content_node.resolve(path, context.dest_node.lang, true)
          if node
            context.website.ext.item_tracker.add(context.dest_node, :node_meta_info, node.alcn)
            context.dest_node.route_to(node)
          else
            nil
          end
        end.compact
      end

      LINK_DOCUMENT_ATTRS = {'type' => 'text/html'} #:nodoc:
      LINK_DOCUMENT_TYPES = %w{start next prev contents index glossary chapter section subsection appendix help} #:nodoc:

      # Return a string containing HTML link tags to the links from the 'link' meta information.
      def self.links_from_link_meta_info(context)
        link_mi = Marshal.load(Marshal.dump(context.content_node['link'] || {}))
        result = ''

        # Add user defined javascript and CSS links
        resolve_paths(context, link_mi.delete('javascript')).each do |file|
          result += "\n<script type=\"text/javascript\" src=\"#{file}\"></script>"
        end
        resolve_paths(context, link_mi.delete('css')).each do |file|
          result += "\n<link rel=\"stylesheet\" href=\"#{file}\" type=\"text/css\" />"
        end

        # add generic links
        link_mi.sort.each do |link_type, vals|
          link_type = link_type.downcase
          [vals].flatten.each do |val|
            val = {'href' => val} if val.kind_of?(String)
            val['rel'] ||= link_type
            val = LINK_DOCUMENT_ATTRS.merge(val) if LINK_DOCUMENT_TYPES.include?(link_type)
            href = val.delete('href')
            href = resolve_paths(context, href).first if href
            if href
              result << "\n<link href=\"#{href}\" "
              val.sort.each {|k,v| result << "#{k}=\"#{ERB::Util.h(v)}\" "}
              result << "/>"
            else
              context.website.logger.error do
                "No link target specified for link type '#{link_type}' in 'link' meta information in <#{context.content_node}>"
              end
            end
          end
        end

        result
      end

    end

  end
end
