# TODO(should be done somewhere else) add CommandPlugin instance to the global CommandParser.
      # TODO(make command parser work - special PluginManager (only used in CLI))
      #Webgen::Plugin.config.keys.find_all {|klass| klass.ancestors.include?( Webgen::CommandPlugin )}.each do |cmdKlass|
      #  add_cmdparser_command( Webgen::Plugin.config[cmdKlass].obj )
      #end
