module WebgenDocuPlugins

  class VersionTag < Tags::DefaultTag

    summary "Shows the version number of webgen"

    tag 'version'

    def process_tag( tag, node, refNode )
      Webgen::VERSION.join( '.' )
    end

  end

  class DescribeTag < Tags::DefaultTag

    summary "Shows options for the specified file handler"
    add_param 'plugin', nil, 'The plugin which should be described'
    set_mandatory 'plugin', true

    tag 'describe'

    def initialize
      super
      @processOutput = false
    end

    def process_tag( tag, node, refNode )
      filehandler = get_param( 'plugin' )
      self.logger.debug { "Describing tag #{filehandler}" }
      plugin = Webgen::Plugin.config.find {|k,v| v.plugin == filehandler }
      self.logger.warn { "Could not describe plugin '#{filehandler}' as it does not exist" } if plugin.nil?
      ( plugin.nil? ? '' : format_data( plugin[1] ) )
    end

    def format_data( data )
      s = "<table>"
      row = lambda {|desc, value| "<tr style='vertical-align: top'><td style='font-weight:bold'>#{CGI::escapeHTML( desc )}:</td><td>#{value}</td></tr>" }

      # Plugin and ancestors
      ancestors = data.klass.ancestor_classes[1..-1].collect {|k| Webgen::Plugin.config[k].plugin}.join(', ')
      s += row['Plugin name', CGI::escapeHTML( data.plugin + (ancestors.empty? ? '' : " (#{ancestors})" ) )]

      # summary, description
      [['Summary', 'summary'], ['Description', 'description']].each do |desc, name|
        s += row[desc, CGI::escapeHTML( data.send( name ) )] if eval( "data.#{name}" )
      end

      # dependencies
      s += row['Dependencies', CGI::escapeHTML( data.dependencies.join( ', ') )] if data.dependencies

      # parameters
      unless data.params.nil?
        s += row['Parameters', format_params( data.params )]
      end

      # used meta info
      s += row['Used meta information', CGI::escapeHTML( data.used_meta_info.join( ', ') )] if data.used_meta_info

      # tag name, file ext
      s += row['Name of tag', (data.tag == :default ? "Default tag" : data.tag)] if data.tag
      s += row['Handled paths', data.path.collect {|p| CGI::escapeHTML( p )}.join('<br />')] if data.path

      # Show all registered handlers
      data.table.keys.find_all {|k| /^registered_/ =~ k.to_s }.each do |k|
        s += row[k.to_s.sub( /^registered_/, '' ).tr('_', ' ').capitalize + " name", data.send( k )]
      end

      s += "</table>"
    end

    def format_params( params )
      params.sort.collect do |k,v|
        "<span style='color: red'>#{v.name}</span>" + \
        ( v.mandatory.nil? \
          ? "&nbsp;=&nbsp;<span style='color: blue'>#{CGI::escapeHTML( v.default.inspect )}</span>" \
          : " (=" + ( v.mandatoryDefault ? "default " : "" ) + "mandatory parameter)" ) + \
        ": #{CGI::escapeHTML( v.description )}"
      end.join( "<br />\n" )
    end

  end

end
