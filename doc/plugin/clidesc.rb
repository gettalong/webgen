require 'cgi'

module WebgenDocuPlugins

  class CliDescTag < Tags::DefaultTag

    summary "Describes the CLI interface"

    tag 'clidesc'

    def initialize
      super
      @processOutput = false
    end

    def process_tag( tag, node, refNode )
      wcp = Webgen::WebgenCommandParser.new
      output = ''
      output << "<p><b>Global Options:</b></p>"
      output << "<pre>#{CGI::escapeHTML(wcp.options.summarize.to_s)}</pre>"
      output << "<p><b>Commands:</b></p>"
      output << "<dl>"
      output << show_command( wcp.main_command )
      output << "</dl>"
    end

    def show_command( cmd )
      output = ''
      cmd.commands.sort.each do |name, command|
        output << "<dt>#{name}</dt>"
        output << "<dd>#{CGI::escapeHTML(command.short_desc)}<br />#{CGI::escapeHTML(command.description)+'<br />' if command.description}"
        output << "#{CGI::escapeHTML(command.usage)}"
        output << "<pre>#{CGI::escapeHTML(command.options.summarize.to_s)}</pre>"
        if command.has_commands?
          output << "<dl>"
          output << show_command( command )
          output << "</dl>"
        end
        output << "</dd>"
      end
      output
    end

  end

end
