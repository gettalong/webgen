require 'yaml'
require 'logger'
require 'tsort'
require 'find'
require 'webgen/config'
require 'webgen/listener'
require 'webgen/content'
require 'facets/core/kernel/constant'

module Webgen


  # Helper class for calculating plugin dependencies.
  class DependencyHash < Hash
    include TSort
    alias tsort_each_node each_key
    def tsort_each_child(node, &block); fetch(node).each(&block) end
  end


  # Used for logging the messages of plugin instances.
  class Logger < ::Logger

    def initialize( logdev = STDERR )
      super( logdev, 0, 0 )
      self.level = ::Logger::ERROR
      self.formatter = Proc.new do |severity, timestamp, progname, msg|
        if self.level == ::Logger::DEBUG
          "%5s -- %s: %s\n" % [severity, progname, msg ]
        else
          "%5s -- %s\n" % [severity, msg]
        end
      end
    end

  end


  # This module gets mixed into plugin classes and provides some utility methods.
  module Plugin

    # Returns the name of the plugin.
    attr_reader :plugin_name

    # Invoked by the plugin manager after creating an object for setting the +plugin_manager+ and
    # the +name+ of the plugin.
    def set_plugin_infos( plugin_manager, name )
      @plugin_manager = plugin_manager
      @plugin_name = name
    end

    # Logs the result of the +block+ using the severity level +sev_level+. Uses the logger provided
    # by the plugin manager.
    def log( sev_level, &block )
      if @plugin_manager.logger
        source = @plugin_name + '#' + caller[0][%r"`.*"][1..-2]
        @plugin_manager.logger.send( sev_level, source, &block )
      end
      nil
    end

    # Returns the value of the parameter +name+ for +plugin+. If +plugin+ is not set, the plugin
    # name of the current object is used.
    def param( name, plugin = nil )
      @plugin_manager.param( name, plugin || @plugin_name )
    end

  end


  class SpecialHash < Hash

    def get( *list )
      h = self; list.each {|name| h = h[name]; break if h.nil?}; h
    end

    def []( name )
      case name
      when Regexp
        self.select {|k,v| k =~ name}
      else
        super
      end
    end

  end


  # Main class for managing plugins.
  #
  # = PluginManager class
  #
  # Provides the following functionality:
  # * loads plugins and resources from plugin bundles
  # * resolves load and runtime dependencies when instantiating a plugin
  # * resolves current values for plugin parameters using configurator objects
  #
  # = Plugin bundles
  #
  # Plugin bundles are directories with the extension <tt>.plugin</tt>. Each plugin bundle can contain
  # * zero or more plugins
  # * zero or more resource files
  # * optional plugin documentation
  # * optional plugin test cases
  #
  # == <tt>plugin.yaml</tt> - Specifies plugins included in bundle
  #
  # Plugins and associated information are specified in the file <tt>plugin.yaml</tt>. If this file
  # does not exist, it just means that the plugin bundle does not define any plugins. A sample file
  # looks like this:
  #
  #   PluginCategory/PluginName:
  #     about:
  #       summary: Summary for the plugin
  #       author: Name of author
  #     plugin:
  #       file: plugin_file.rb
  #       class: PluginName
  #       load_deps: [LoadDepPlugin]
  #       run_deps: [RunDepPlugin]
  #       docufile: documentation.page
  #     params:
  #       sample_param:
  #         default: default value
  #         desc: A small description for the parameter
  #       another_param:
  #         default: ~
  #
  #   SimplePlugin: ~
  #
  # Two plugins, <tt>PluginCategory/PluginName</tt> and +SimplePlugin+ are defined in this file. The
  # first plugin specifies much information about the plugin, including information about the plugin
  # itself in the +plugin+ section and its parameters in the +params+ section. The SimplePlugin uses
  # the smallest possible way of defining a plugin by relying on the default values.
  #
  # You can add any information you want! It is later accessible through the
  # PluginManager#plugin_infos Hash.
  #
  # The PluginManager uses information from the +plugin+ and the +params+ section. Following is a
  # list of all useable keys in the +plugin+ section and their default values:
  #
  # +file+:: The file in which the plugin class is declared. Default value: <tt>plugin.rb</tt>.
  # +class+:: The plugin class. This class is later used to instantiate the plugin. The default
  #           value is constructed from the plugin name by substituting <tt>/</tt> with <tt>::</tt>.
  # +load_deps+:: An array of load time dependencies of the plugin, ie. other plugins that are
  #               needed because of constants definition or for initializing. Default value: <tt>[]</tt>.
  # +run_deps+:: An array of runtime dependencies of the plugin. Default value: <tt>[]</tt>
  # +docufile+:: The name of a file in WebPage Format containing documentation for the plugin.
  #              Default value: <tt>documentation.page</tt>.
  #
  # The +params+ section is used to define parameters for the plugin. If no default value is
  # specified, +nil+ becomes the default value.
  #
  # A plugin class can be any Ruby class that can be initialized without any arguments. After
  # resolving the plugin class, the Plugin module is mixed into the class which provides utility
  # methods for plugins. When a plugin object gets created, it has no access to the plugin manager
  # in the #initialize method since the values are set afterwards. To come around this problem a
  # plugin class can define a method +init_plugin+ which gets called after the plugin manager
  # variable has been set and which can be used to initialize the plugin.
  #
  # == <tt>resource.yaml</tt> - Specifies resources included in bundle
  #
  # Each plugin bundle can include resources. The file <tt>resource.yaml</tt> tells the
  # PluginManager which resources have which name and which associated information. If this file
  # does not exist, it just means that the plugin bundle does not include any resources!
  #
  # A sample file looks like this:
  #
  #   resources/templates/*/:
  #     name: webgen/website/template/$basename
  #     desc: A small description for the template $basename.
  #
  #   resources/styles/*/*/:
  #     name: webgen/website/style/$dir1/$basename
  #
  # The top level keys are just file globs useable by <tt>Dir.glob</tt>. All files under the plugin
  # bundle directory matching such a glob are considered to be resources. The only mandatory key for
  # such a glob is +name+ which specifies the name of the resource. This name can later be used to
  # access it. The PluginManager performs a simple variable expansion on all values. The following
  # variables can be used (for the examples consider the resource
  # <tt>resources/images/emoticons/smile.png</tt>):
  #
  # <tt>$basename</tt>:: Returns the basename of the resource, ie. <tt>smile.png</tt>
  # <tt>$extname</tt>:: Returns the extension of the resource, ie. <tt>png</tt>
  # <tt>$basename_no_ext</tt>:: Returns the basename without the extension, ie. <tt>smile</tt>
  # <tt>$dirN</tt>:: Returns the Nth directory name, ie. for N=1 <tt>emoticons</tt>, for N=2 <tt>images</tt>, ...
  #
  # == Plugin documentation file
  #
  # The plugin documentation file has to be in WebPage Format. A processing pipeline for each block
  # should always be specified sothat the blocks get rendered correctly!
  #
  # A documentation file should include at least the block +documentation+ which has in-depth
  # documentation for the plugin. The optional block +usage+ can be used to show how the plugin
  # works or document use cases.
  #
  # == Plugin test cases
  #
  # All Ruby source files in the directory +tests+ under a plugin bundle are considered to be test
  # cases for the plugins included in the bundle. It is good practice to include test sothat the end
  # user can verify if a given plugin will run correctly on his installation!
  #
  # = Configurators
  #
  # Configurator objects are used to determine the current values of plugin parameters. The
  # PluginManager uses a chain of such objects to determine a parameter value. It invokes the
  # configurators in the reverse order (so, first the last configurator is invoked, then the next to
  # last and so on) with the names of the parameter and the plugin and the current value (the
  # default value for a parameter is used at the beginning). The PluginManager stops if there are no
  # more configurators or if a configurator has issued a stop and returns the value for the
  # parameter.
  #
  # A configurator object must respond to the +param+ method and which has to take three
  # parameters:
  #
  # 1. the name of the parameter
  # 2. the name of the plugin
  # 3. the current value for the parameter
  #
  # The method needs to return an array with two values: the first value can either be +true+ or
  # +false+ and tells the PluginManager to stop here or to go on to the next configurator and the
  # second value has to be the value for the parameter.
  #
  # A small example with two sample configurator objects:
  #
  #   class SampleConfigurator
  #
  #     def initialize( value, stop ); @value, @stop = value, stop; end
  #
  #     def param( name, plugin, cur_val )
  #       ([plugin,name] == ['TestPlugin', 'test'] ? [@stop, @value] : [false, cur_val])
  #     end
  #   end
  #
  #   stop_configurator = SampleConfigurator.new( 'stop', true )
  #   no_stop_configurator = SampleConfigurator.new( 'no stop', false )
  #
  #   pm = Webgen::PluginManager.new( [stop_configurator, no_stop_configurator] )
  #   pm.param( 'test', 'TestPlugin' )     # -> 'stop'
  #   pm = Webgen::PluginManager.new( [no_stop_configurator, stop_configurator] )
  #   pm.param( 'test', 'TestPlugin' )     # -> 'stop'
  #   pm.param( 'param', 'OtherPlugin' )   # returns the default value
  #
  # So, first we create a simple configurator class and then two configurator objects: one which
  # stops the PluginManager and one which doesn't. As you can see it outputs 'stop' both times: the
  # first time because the +stop_configurator+ is the first configurator in the chain (and therefore
  # asked last) and the second time because it stops the PluginManager from further asking other
  # configurators (in our case the +no_stop_configurator+).
  #
  class PluginManager < Module

    # Returns the Hash with the plugin infos, ie. the values from the <tt>plugin.yaml</tt> files.
    attr_accessor :plugin_infos

    # Returns the Hash with the instantiated plugins.
    attr_accessor :plugins

    # Returns the Hash with the resources defined in the <tt>resource.yaml</tt> files.
    attr_accessor :resources

    # Returns the logger for the object.
    attr_accessor :logger

    # Returns the array of configurators.
    attr_accessor :configurators

    # Initializes a new PluginManager object using the optional +configurators+ and +logger+
    # parameters.
    def initialize( configurators = [], logger = Logger.new )
      @plugins = {}
      @configurators = configurators
      @logger = logger
      @loaded_bundles = []
      @loaded_features = []
      @plugin_infos = SpecialHash.new
      @resources = SpecialHash.new
    end

    # Can be used by a plugin to load files in its plugin bundle.
    def load_local( file )
      file = (File.basename(file).index('.').nil? ? file + '.rb' : file )
      load_plugin_file( File.join( File.dirname( caller[0][/^[^:]+/] ), file ) )
    end

    # Loads all plugin bundles, ie. directories with the extension +.plugin+, from the given
    # directories +dirs+.
    def load_all_plugin_bundles( dirs )
      Find.find( *dirs ) do |path|
        if FileTest.directory?( path ) && path =~ /\.plugin$/
          load_plugin_bundle( path )
          Find.prune
        end
      end
    end

    # Loads a single plugin bundle from +dir+.
    def load_plugin_bundle( dir )
      dir = File.expand_path( dir )
      return if @loaded_bundles.include?( dir )
      @loaded_bundles << dir
      load_plugin_infos( dir )
      load_resources( dir )
    end

    # Initializes the +plugins+ and all their dependencies. There is no need to call this method
    # from your code since not initialized plugins are automatically initialized on access!
    def init_plugins( plugins = @plugin_infos.keys )
      plugins.each do |plugin|
        deps = all_plugin_deps( plugin, 'load_deps' ).tsort
        deps.each {|plugin_name| init_plugin( plugin_name ) }
        deps.each {|dep| init_plugins( [@plugin_infos[dep]['plugin']['run_deps']].flatten - @plugins.keys ) }
      end
    end

    # Returns the plugin +plugin_name+. The plugin is automatically initialized if it has not been
    # initialized yet!
    def []( plugin_name )
      init_plugins( [plugin_name] ) if !@plugins.has_key?( plugin_name )
      @plugins[plugin_name]
    end

    # Returns the parameter +name+ for +plugin+ by using the configurators. Raises an error if no
    # such parameter exists.
    def param( name, plugin )
      raise "No such parameter #{name} for plugin #{plugin}" unless @plugin_infos.has_key?( plugin ) && @plugin_infos[plugin]['params'].has_key?( name )
      stop, value = false, @plugin_infos.get( plugin, 'params', name, 'default' )
      @configurators.reverse.each do |configurator|
        stop, value = configurator.param( name, plugin, value )
        break if stop
      end
      value
    end

    # TODO: redo, docu file should be in WebPage format, different sections
    # -> usage (general usage of the plugin), documentation (in-depth documentation)
    def documentation_for( plugin, section = 'documenation', type = :text )
      return '' unless @plugin_infos.has_key?( plugin )
      content = ''
      docufile = @plugin_infos[plugin]['plugin']['docufile']
      docufile = File.join( @plugin_infos[plugin]['plugin']['dir'], docufile )
      if File.exists?( docufile )
        page = Page.create_from_file( docufile )
        content = page.blocks[section].content if page.blocks.has_key?( section )
      end
      content
    end

    #######
    private
    #######

    def load_plugin_infos( plugin_dir )
      file = File.join( plugin_dir, 'plugin.yaml')
      return unless File.exist?( file )

      info = YAML::load( File.read( file ) )
      raise "#{file} is invalid" unless info.kind_of?( Hash )
      info.each do |name, infos|
        raise "Plugin already defined" if @plugin_infos.has_key?( name )
        @plugin_infos[name] = (infos || {})

        @plugin_infos[name]['plugin'] ||= {}
        @plugin_infos[name]['plugin']['name'] = name
        @plugin_infos[name]['plugin']['dir'] = plugin_dir
        @plugin_infos[name]['plugin']['file'] ||= 'plugin.rb'
        @plugin_infos[name]['plugin']['class'] ||= name.split('/').join('::')
        @plugin_infos[name]['plugin']['run_deps'] ||= []
        @plugin_infos[name]['plugin']['load_deps'] ||= []
        @plugin_infos[name]['plugin']['docufile'] ||= 'documentation.page'

        @plugin_infos[name]['params'] ||= {}
      end
    end

    def load_resources( plugin_dir )
      file = File.join( plugin_dir, 'resource.yaml' )
      return unless File.exist?( file )

      resources = YAML::load( File.read( file ) )
      raise "#{file} is invalid" unless resources.kind_of?( Hash )
      resources.each do |res, infos|
        Dir[File.join( plugin_dir, res )].each do |res_file|
          res_infos = get_res_infos( res_file, infos.merge('src' => res_file ) )
          raise "There is already a resource called #{res_infos['name']}" if @resources.has_key?( res_infos['name'] )
          @resources[res_infos['name']] = res_infos
          #TODO: check for duplicate output path
        end
      end
    end

    def get_res_infos( res_file, infos )
      substs = Hash.new {|h,k| h[k] = "$" + k }
      substs.merge!({
        'basename' => File.basename( res_file ),
        'basename_no_ext' => File.basename( res_file, '.*' ),
        'extname' => File.extname( res_file )[1..-1],
        :dirnames => File.dirname( res_file ).split(File::SEPARATOR),
      })
      Hash[*infos.collect do |key, value|
        [key, value.to_s.gsub( /\$\w+/ ) do |m|
           if m =~ /^\$dir(\d+)$/
             substs[:dirnames][-($1.to_i)]
           else
             substs[m[1..-1]]
           end
         end]
      end.flatten]
    end

    def load_plugin_file( file )
      unless @loaded_features.include?( file )
        @loaded_features.push( file )
        begin
          module_eval( File.read( file ), file )
        rescue Exception
          @loaded_features.pop
          raise "Error while loading file: #{$!.message}"
        end
      end
    end

    def init_plugin( name )
      return if @plugins.has_key?(name)

      file = File.join( @plugin_infos[name]['plugin']['dir'], @plugin_infos[name]['plugin']['file'] )
      load_plugin_file( file )

      klass = constant(@plugin_infos[name]['plugin']['class'])
      klass.module_eval { include( Plugin ) }
      @plugins[name] = klass.new
      @plugins[name].set_plugin_infos( self, name )
      @plugins[name].init_plugin if @plugins[name].respond_to?(:init_plugin)
    end

    def all_plugin_deps( name, type, dep = DependencyHash.new )
      if @plugin_infos.has_key?( name )
        dep[name] = [@plugin_infos[name]['plugin'][type]].flatten
        dep[name].each {|d| all_plugin_deps(d, type, dep) unless dep.has_key?(d)}
      else
        raise "No plugin named '#{name}' found!"
      end
      dep
    end

  end

end
