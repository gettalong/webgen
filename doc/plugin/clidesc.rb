require 'cgi'

module OtherPlugins

  class CliDescTag < Tags::DefaultTag

    summary "Describes the CLI interface"
    depends_on 'Tags'

    def initialize
      super
      @processOutput = false
      register_tag( 'clidesc' )
    end

    def process_tag( tag, node, refNode )
      wcp = Webgen::WebgenCommandParser.new
      output = ''
      output << "<p><b>Global Options:</b></p>"
      output << "<pre>#{CGI::escapeHTML(wcp.options.summarize.to_s)}</pre>"
      output << "<p><b>Commands:</b></p>"
      output << "<dl>"
      wcp.commands.sort.each do |name, command|
        output << "<dt>#{name}</dt>"
        output << "<dd>#{CGI::escapeHTML(command.description)}<br />"
        output << "#{CGI::escapeHTML(command.usage)}<br />"
        output << "<pre>#{CGI::escapeHTML(command.options.summarize.to_s)}</pre>"
        output << "</dd>"
      end
      output << "</dl>"
    end

  end

end
