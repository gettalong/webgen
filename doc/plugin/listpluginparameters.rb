require 'set'

class ListPluginParametersTag < Tags::DefaultTag

  infos( :name => 'WebgenDocu/PluginParameterRefTag',
         :summary => "Lists all available plugin parameters"
         )

  register_tag 'listPluginParameters'

  def initialize( plugin_manager )
    super
    @process_output = false
  end

  def process_tag( tag, chain )
    plugins = @plugin_manager.plugins.select {|k,v| k !~ /^WebgenDocu/ }

    mydata = {}
    plugins.each do |name, plugin|
      next if plugin.class.config.params.empty?
      (mydata[name[/^.*?(?=\/)/].gsub(/([A-Z][a-z])/, ' \1').strip] ||= []) << plugin
    end

    output = "<dl>\n"
    mydata.sort.each do |cat, plugins|
      output << "<dt>#{cat}</dt><dd><dl>"
      plugins.sort {|a,b| a.class.plugin_name <=> b.class.plugin_name}.each do |data|
        output << "<dt>#{data.class.plugin_name}</dt>\n"
        output << "<dd>#{@plugin_manager['WebgenDocu/DescribeTag'].format_params( data.class.config.params )}</dd>\n"
      end
      output << "</dl></dd>"
    end
    output << "</dl>\n"
  end

end
