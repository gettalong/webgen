require 'cgi'

module Tag

  # Includes a file verbatim. All HTML special characters are escaped.
  class IncludeFile < DefaultTag

    def process_tag( tag, body, context )
      content = ''
      begin
        filename = param( 'filename' )
        filename = File.join( context.ref_node.parent.node_info[:src], param( 'filename' ) ) unless filename =~ /^(\/|\w:)/
        content = File.read( filename )
        (context.cache_info[self.plugin_name] ||= []) << filename
      rescue
        log(:error) { "Given filen <#{filename}> specified in <#{context.ref_node.absolute_lcn}> does not exist or can't be read" }
      end
      content = CGI::escapeHTML( content ) if param( 'escapeHTML' )

      [content, param( 'processOutput' )]
    end

    def cache_info_changed?( data, node )
      data.any? {|filename| @plugin_manager['Core/FileHandler'].file_changed?( filename ) }
    end

  end

end
