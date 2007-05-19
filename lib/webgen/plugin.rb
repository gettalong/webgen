require 'yaml'
require 'logger'
require 'tsort'
require 'find'
require 'webgen/config'
require 'webgen/listener'
require 'facets/core/kernel/constant'
require 'bluecloth'

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


  module Plugin

    attr_reader :plugin_name

    def set_plugin_infos( plugin_manager, name )
      @plugin_manager = plugin_manager
      @plugin_name = name
    end

    def log( sev_level, &block )
      if @plugin_manager.logger
        source = @plugin_name + '#' + caller[0][%r"`.*"][1..-2]
        @plugin_manager.logger.send( sev_level, source, &block )
      end
      nil
    end

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

  class PluginManager < Module

    attr_accessor :plugin_infos
    attr_accessor :plugins
    attr_accessor :resources

    attr_accessor :logger
    attr_accessor :configurators

    def initialize( configurators = [], logger = Logger.new )
      @plugins = {}
      @configurators = configurators
      @logger = logger
      @loaded_features = []
      @plugin_infos = SpecialHash.new
      @resources = SpecialHash.new
    end

    # Can be used by a plugin to load files in the plugin bundle.
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

    def param( name, plugin )
      raise "No such parameter #{name} for plugin #{plugin}" unless @plugin_infos.has_key?( plugin ) && @plugin_infos[plugin]['params'].has_key?( name )
      stop, value = false, @plugin_infos[plugin]['params'][name]['default']
      @configurators.reverse.each do |configurator|
        stop, value = configurator.param( name, plugin, value )
        break if stop
      end
      value
    end

    # TODO: redo, docu file should be in WebPage format, different sections
    # -> usage (general usage of the plugin), documentation (in-depth documentation)
    def documentation_for( plugin, type = :text )
      return '' unless @plugin_infos.has_key?( plugin )
      content = ''
      docufile = @plugin_infos[plugin]['plugin']['docufile']
      docufile = File.join( @plugin_infos[plugin]['plugin']['dir'], docufile )
      if File.exists?( docufile )
        content = File.read( docufile )
        content = BlueCloth.new( content ).to_html if type == :html
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
