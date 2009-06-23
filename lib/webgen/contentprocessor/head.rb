# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Inserts additional links to CSS/JS files and other HTML head meta info directly before the HTML
  # head end tag.
  #
  # The data used by this content processor is taken from the Context object. Therefore this
  # processor should be the last in the processing pipeline so that all other processors have been
  # able to set the data.
  #
  # The key <tt>:cp_head</tt> of <tt>context.options</tt> is used and it has to be a Hash with the
  # following values:
  #
  # [:js_file] An array of already resolved relative or absolute paths to Javascript files.
  # [:js_inline] An array of Javascript fragments to be inserted directly into the head section.
  # [:css_file] An array of already resolved relative or absolute paths to CSS files.
  # [:css_inline] An array of CSS fragments to be inserted directly into the head section.
  # [:meta] A hash with key-value pairs from which <tt>meta</tt> tags are generated. The keys and
  #         the values will be properly escaped before insertion. The entries in the meta
  #         information <tt>meta</tt> of the content node are also used and take precedence over
  #         these entries.
  class Head

    include Webgen::Loggable

    HTML_HEAD_END_RE = /<\/head\s*>/i #:nodoc:

    # Insert the additional header information.
    def call(context)
      require 'erb'
      context.content.sub!(HTML_HEAD_END_RE) do |match|
        result = ''
        if context[:cp_head].kind_of?(Hash)
          context[:cp_head][:js_file].each do |js_file|
            result += "\n<script type=\"text/javascript\" src=\"#{js_file}\"></script>"
          end if context[:cp_head][:js_file].kind_of?(Array)

          context[:cp_head][:js_inline].each do |content|
            result += "\n<script type=\"text/javascript\">\n#{content}\n</script>"
          end if context[:cp_head][:js_inline].kind_of?(Array)

          context[:cp_head][:css_file].each do |css_file|
            result += "\n<link rel=\"stylesheet\" href=\"#{css_file}\" type=\"text/css\"/>"
          end if context[:cp_head][:css_file].kind_of?(Array)

          context[:cp_head][:css_inline].each do |content|
            result += "\n<style type=\"text/css\"><![CDATA[/\n#{content}\n]]></style>"
          end if context[:cp_head][:css_inline].kind_of?(Array)

          context[:cp_head][:meta].merge(context.node['meta'] || {}).each do |name, content|
            result += "\n<meta name=\"#{ERB::Util.h(name)}\" content=\"#{ERB::Util.h(content)}\" />"
          end if context[:cp_head][:meta].kind_of?(Hash)
        end
        result + match
      end
      context
    end

  end

end
