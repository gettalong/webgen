require 'yaml'
require 'logger'
require 'tsort'
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
      source = @plugin_name + '#' + caller[0][%r"`.*"][1..-2]
      @plugin_manager.logger.send( sev_level, source, &block ) if @plugin_manager.logger
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

    def load_local( file )
      file = (File.basename(file).index('.').nil? ? file + '.rb' : file )
      load_plugin_file( File.join( File.dirname( caller[0][/^[^:]+/] ), file ) )
    end

    def []( plugin )
      load_plugins( [plugin] ) if !@plugins.has_key?( plugin )
      @plugins[plugin]
    end

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

    def load_from_dir( plugin_dir )
      dir = File.expand_path( plugin_dir )
      load_plugin_infos( dir )
      load_resources( dir )
    end

    def load_plugins( plugins = @plugin_infos.keys )
      plugins.each do |plugin|
        deps = all_plugin_deps( plugin, 'load_deps' ).tsort
        deps.each {|plugin_name| load_plugin( plugin_name ) }
        deps.each {|dep| load_plugins( [@plugin_infos[dep]['plugin']['run_deps']].flatten - @plugins.keys ) }
      end
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

    #######
    private
    #######

    def load_plugin_infos( plugin_dir )
      file = File.join( plugin_dir, 'plugin.yaml')
      return unless File.exist?( file )
      info = YAML::load( File.read( file ) )
      info.each do |name, infos|
        raise "Plugin already defined" if @plugin_infos.has_key?( name )
        @plugin_infos[name] = infos

        @plugin_infos[name]['about'] ||= {}
        @plugin_infos[name]['about']['summary'] ||= 'TODO'

        @plugin_infos[name]['plugin'] ||= {}
        @plugin_infos[name]['plugin']['name'] = name
        @plugin_infos[name]['plugin']['dir'] = plugin_dir
        @plugin_infos[name]['plugin']['file'] ||= 'plugin.rb'
        @plugin_infos[name]['plugin']['class'] ||= name.split('/').join('::')
        @plugin_infos[name]['plugin']['run_deps'] ||= []
        @plugin_infos[name]['plugin']['load_deps'] ||= []
        @plugin_infos[name]['plugin']['docufile'] = 'documentation.rdoc'

        @plugin_infos[name]['params'] ||= {}
      end
    end

    def load_resources( plugin_dir )
      file = File.join( plugin_dir, 'resource.yaml' )
      return unless File.exist?( file )
      resources = YAML::load( File.read( file ) )
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
        'extname' => File.extname( res_file ),
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
        rescue
          @loaded_features.pop
          raise
        end
      end
    end

    def load_plugin( name )
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
      end
      dep
    end

  end

end
