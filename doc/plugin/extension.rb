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
    pluginfile = (plugin.index('/') ? plugin.downcase + '.page' : plugin.downcase + '/index.page')
    "<a href=\"{relocatable: /documentation/plugins/#{pluginfile}}\">#{plugin}</a>"
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
    plugin = @plugin_manager[plugin_name]
    log(:warn) { "Could not describe plugin '#{plugin_name}' as it does not exist" } if plugin.nil?
    ( plugin.nil? ? '' : format_data( plugin.class.config ) )
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

    # tag names, file ext
    s += row['Handled tags', (data.infos[:tags].collect {|t| t == :default ? "Default tag" : t}.join(', '))] if data.infos[:tags]
    s += row['Handled paths', data.infos[:path_patterns].collect {|rank, path| CGI::escapeHTML( path )}.join('<br />')] if data.infos[:path_patterns]

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
      ( v.mandatory.nil? \
        ? "&nbsp;:&nbsp;<span class='param-default-value'>#{CGI::escapeHTML( v.default.inspect )}</span>" \
        : " (=" + ( v.mandatory_default ? "default " : "" ) + "mandatory parameter)" ) + \
      "<br /><span class='param-description'>#{CGI::escapeHTML( v.description )}</span></p>"
    end.join( "\n" )
  end

end
