require 'set'

module WebgenDocuPlugins

  class ListPluginParametersTag < Tags::DefaultTag

    summary "Lists all available plugin parameters"

    tag 'listPluginParameters'

    def initialize
      super
      @processOutput = false
    end

    def process_tag( tag, node, refNode )
      plugins = Webgen::Plugin.config.select {|k,v| k.name !~ /^WebgenDocuPlugins::/ }

      mydata = {}
      plugins.each do |klass, data|
        next if data.params.nil?
        (mydata[klass.name[/^.*?(?=::)/].gsub(/([A-Z][a-z])/, ' \1').strip] ||= []) << data
      end

      output = "<dl>\n"
      mydata.sort.each do |cat, plugins|
        output << "<dt>#{cat}</dt><dd><dl>"
        plugins.sort {|a,b| a.plugin <=> b.plugin}.each do |data|
          output << "<dt>#{data.plugin}</dt>\n"
          output << "<dd>#{Webgen::Plugin['DescribeTag'].format_params( data.params )}</dd>\n"
        end
        output << "</dl></dd>"
      end
      output << "</dl>\n"
    end

  end

end
