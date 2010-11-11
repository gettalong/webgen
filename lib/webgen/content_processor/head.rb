# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Inserts additional links to CSS/JS files and other HTML head meta info directly before the HTML
  # head end tag.
  #
  # The data used by this content processor is taken from the Context object. Therefore this
  # processor should be the last in the processing pipeline so that all other processors have been
  # able to set the data.
  #
  # The key <tt>:cp_head</tt> of <tt>context.persistent</tt> is used (the normal
  # <tt>context.options</tt> won't do because the data needs to be shared 'backwards' during the
  # rendering) and it has to be a Hash with the following values:
  #
  # [:js_file] An array of already resolved relative or absolute paths to Javascript files.
  # [:js_inline] An array of Javascript fragments to be inserted directly into the head section.
  # [:css_file] An array of already resolved relative or absolute paths to CSS files.
  # [:css_inline] An array of CSS fragments to be inserted directly into the head section.
  # [:meta] A hash with key-value pairs from which <tt>meta</tt> tags are generated. The keys and
  #         the values will be properly escaped before insertion. The entries in the meta
  #         information <tt>meta</tt> of the content node are also used and take precedence over
  #         these entries.
  #
  # Duplicate values will be removed from the above mentioned arrays before generating the output.
  class Head

    include Webgen::Loggable

    HTML_HEAD_END_RE = /<\/head\s*>/i #:nodoc:

    LINK_DOCUMENT_ATTRS = {'type' => 'text/html'} #:nodoc:
    LINK_DOCUMENT_TYPES = %w{start next prev contents index glossary chapter section subsection appendix help} #:nodoc:

    # Insert the additional header information.
    def call(context)
      require 'erb'
      context.content.sub!(HTML_HEAD_END_RE) do |match|
        result = ''

        # add content set programmatically
        if context.persistent[:cp_head].kind_of?(Hash)
          context.persistent[:cp_head][:js_file].uniq.each do |js_file|
            result += "\n<script type=\"text/javascript\" src=\"#{js_file}\"></script>"
          end if context.persistent[:cp_head][:js_file].kind_of?(Array)

          context.persistent[:cp_head][:js_inline].uniq.each do |content|
            result += "\n<script type=\"text/javascript\">\n#{content}\n</script>"
          end if context.persistent[:cp_head][:js_inline].kind_of?(Array)

          context.persistent[:cp_head][:css_file].uniq.each do |css_file|
            result += "\n<link rel=\"stylesheet\" href=\"#{css_file}\" type=\"text/css\"/>"
          end if context.persistent[:cp_head][:css_file].kind_of?(Array)

          context.persistent[:cp_head][:css_inline].uniq.each do |content|
            result += "\n<style type=\"text/css\"><![CDATA[/\n#{content}\n]]></style>"
          end if context.persistent[:cp_head][:css_inline].kind_of?(Array)
        end
        ((context.persistent[:cp_head] || {})[:meta] || {}).merge(context.node['meta'] || {}).each do |name, content|
          result += "\n<meta name=\"#{ERB::Util.h(name)}\" content=\"#{ERB::Util.h(content)}\" />"
        end

        # add links to other languages of same page
        context.dest_node.tree.node_access[:acn][context.dest_node.acn].
          select {|n| n.alcn != context.dest_node.alcn}.each do |node|
          context.dest_node.node_info[:used_meta_info_nodes] << node.alcn
          result += "\n<link type=\"text/html\" rel=\"alternate\" hreflang=\"#{node.lang}\" "
          result += "href=\"#{context.dest_node.route_to(node)}\" "
          if node['title'] && !node['title'].empty?
            result += "lang=\"#{node.lang}\" title=\"#{ERB::Util.h(node['title'])}\" "
          end
          result += "/>"
        end

        link = Marshal.load(Marshal.dump(context.node['link'] || {}))

        handle_files = lambda do |files|
          [files].flatten.compact.collect do |file|
            if !Webgen::Node.url(file, false).absolute?
              file = context.node.resolve(file, context.dest_node.lang)
              if file
                context.dest_node.node_info[:used_meta_info_nodes] << file.alcn
                file = context.dest_node.route_to(file)
              else
                log(:error) { "Could not resolve path '#{file}' used in 'link' meta information in <#{context.node}>" }
                context.dest_node.flag(:dirty)
              end
            end
            file
          end.compact
        end

        # Add user defined javascript and CSS links
        handle_files.call(link.delete('javascript')).each do |file|
          result += "\n<script type=\"text/javascript\" src=\"#{file}\"></script>"
        end
        handle_files.call(link.delete('css')).each do |file|
          result += "\n<link rel=\"stylesheet\" href=\"#{file}\" type=\"text/css\" />"
        end

        # add generic links specified via the +link+ meta information
        link.sort.each do |link_type, vals|
          link_type = link_type.downcase
          [vals].flatten.each do |val|
            val = {'href' => val} if val.kind_of?(String)
            val['rel'] ||= link_type
            val = LINK_DOCUMENT_ATTRS.merge(val) if LINK_DOCUMENT_TYPES.include?(link_type)
            if href = val.delete('href')
              href = handle_files.call(href).first
            else
              log(:error) { "No link target specified for link type '#{link_type}' in 'link' meta information in <#{context.node}>" }
            end
            if href
              s = "\n<link href=\"#{href}\" "
              val.sort.each {|k,v| s += "#{k}=\"#{ERB::Util.h(v)}\" "}
              result += s + "/>"
            end
          end
        end

        result + match
      end
      context
    end

  end

end
