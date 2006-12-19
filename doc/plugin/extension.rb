class SvgToPngConverter < FileHandlers::DefaultHandler

  infos( :name => 'File/SvgToPng',
         :summary => "Converts an svg image to png using inkscape"
         )

  register_extension 'svg'

  def create_node( path, parent, meta_info )
    name = File.basename( path, '.svg' ) + '.png'

    node = parent.find {|c| c =~ name }
    if node.nil?
      node = Node.new( parent, name )
      node['title'] = name
      node.meta_info.update( meta_info )
      node.node_info[:src] = path
      node.node_info[:processor] = self
    else
      log(:warn) { "Can't create node <#{node.full_path}> as it already exists (node handled by #{node.node_info[:processor].class.plugin_name})!" }
    end
    node
  end

  def write_node( node )
    if @plugin_manager['Core/FileHandler'].file_modified?( node.node_info[:src], node.full_path )
      `inkscape -e #{node.full_path} #{node.node_info[:src]}`
    end
  end

end


class VersionTag < Tags::DefaultTag

  infos( :name => 'WebgenDocu/VersionTag',
         :summary => "Shows the version number of webgen"
         )

  register_tag 'version'

  def process_tag( tag, chain )
    Webgen::VERSION.join( '.' )
  end

end


class PluginRefTag < Tags::DefaultTag

  infos( :name => 'WebgenDocu/PluginRefTag',
         :summary => "Outputs a link to the given plugin name"
         )

  param 'plugin', nil, 'The plugin which should be referenced'
  set_mandatory 'plugin', true

  register_tag 'plugin'

  def process_tag( tag, chain )
    plugin = param('plugin')
    anchor = plugin.slice!( /#.*$/ )

    if @plugin_manager.plugin_class_for_name( plugin ).nil? && plugin.index('/')
      log(:error) { "Invalid link to plugin: #{plugin}" }
      "INVALID PLUGIN"
    else
      pluginfile = (plugin.index('/') ? plugin.downcase + '.page' : plugin.downcase + '/') + anchor.to_s
      "<span class='plugin-ref'><a href=\"{relocatable: /documentation/plugins/#{pluginfile}}\">#{plugin}</a></span>"
    end
  end

end

class ParamRefTag < Tags::DefaultTag

  infos( :name => 'WebgenDocu/ParamRefTag',
         :summary => "Outputs a link to the plugin responsible for the given param name"
         )

  param 'param', nil, 'The param which should be referenced'
  set_mandatory 'param', true

  register_tag 'param'

  def process_tag( tag, chain )
    plugin, param = param('param').split(':')
    if @plugin_manager.plugin_class_for_name( plugin ).nil? || !@plugin_manager.plugin_class_for_name( plugin ).config.params.has_key?( param )
      log(:error) { "Invalid link to parameter: #{plugin}:#{param}" }
      "INVALID PARAM"
    else
      pluginfile = plugin.downcase + '.page'
      link_text = ( chain.last.node_info[:pagename] == File.basename( pluginfile ) ? param : plugin + ':' + param )
      "<span class='param-ref'><a href=\"{relocatable: /documentation/plugins/#{pluginfile}}\">#{link_text}</a></span>"
    end
  end

end

class DescribeTag < Tags::DefaultTag

  infos( :name => 'WebgenDocu/DescribeTag',
         :summary => "Shows options for the specified plugin"
         )

  param 'plugin', nil, 'The plugin which should be described'
  set_mandatory 'plugin', true

  register_tag 'describe'

  def initialize( pm )
    super
  end

  def process_tag( tag, chain )
    plugin_name = param( 'plugin' )
    log(:debug) { "Describing tag #{plugin_name}" }
    plugin = @plugin_manager.plugin_class_for_name( plugin_name )
    log(:warn) { "Could not describe plugin '#{plugin_name}' as it does not exist" } if plugin.nil?
    ( plugin.nil? ? '' : format_data( plugin.config ) )
  end

  def format_data( data )
    s = "<table class='plugin-info'>"
    row = lambda {|desc, value| "<tr style='vertical-align: top'><th>#{CGI::escapeHTML( desc )}:</th><td>#{value}</td></tr>" }

    # Plugin and ancestors
    ancestors = data.plugin_klass.ancestor_classes[1..-1].collect {|k| "{plugin: #{k.plugin_name}}"}.join(', ')
    s += row['Plugin name', CGI::escapeHTML( data.plugin_klass.plugin_name + (ancestors.empty? ? '' : " (#{ancestors})" ) )]

    # summary, description
    [['Author', :author], ['Summary', :summary], ['Description', :description]].each do |desc, name|
      s += row[desc, CGI::escapeHTML( data.infos[name] )] if data.infos[name]
    end

    # dependencies
    s += row['Dependencies', CGI::escapeHTML( data.dependencies.collect {|k| "{plugin: #{k}}"}.join( ', ') )] unless data.dependencies.empty?

    # parameters
    unless data.params.empty?
      s += row['Parameters', format_params( data.params )]
    end

    # tag names, file ext, default meta info
    s += row['Handled tags', (data.infos[:tags].collect {|t| t == :default ? "Default tag" : t}.join(', '))] if data.infos[:tags]
    s += row['Handled paths', data.infos[:path_patterns].collect {|rank, path| CGI::escapeHTML( path )}.join('<br />')] if data.infos[:path_patterns]
    s += row['Default Meta Information', "<pre>" + CGI::escapeHTML( data.infos[:default_meta_info].to_yaml.sub( /\A---\s*\n/m, '') ) + "</pre>"] if !data.infos[:default_meta_info].nil? && !data.infos[:default_meta_info].empty?

    # Show all registered handlers
    # TODO use new style
    #data.table.keys.find_all {|k| /^registered_/ =~ k.to_s }.each do |k|
    #  s += row[k.to_s.sub( /^registered_/, '' ).tr('_', ' ').capitalize + " name", data.send( k )]
    #end

    s += "</table>"
  end

  def format_params( params )
    params.sort.collect do |k,v|
      "<p class='param'><span class='param-name'>#{v.name}</span>" + \
      ( v.mandatory.nil? ? "" : " (=" + ( v.mandatory_default ? "default ": "" ) + "mandatory parameter)" ) + \
      ":&nbsp;<span class='param-default-value'>#{CGI::escapeHTML( v.default.inspect )}</span>" + \
      "<br /><span class='param-description'>#{CGI::escapeHTML( v.description )}</span></p>"
    end.join( "\n" )
  end

end
