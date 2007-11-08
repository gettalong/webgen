require 'cmdparse'

module Cli

  module Commands

    class About < CmdParse::Command

      def initialize
        super( 'about', false )
        @extended = false
        @show_params = false
      end

      def init_plugin
        self.short_desc = @plugin_manager.plugin_infos.get( plugin_name, 'about', 'summary' )
         self.options = CmdParse::OptionParserWrapper.new do |opts|
           opts.separator "Options:"
           opts.on( '-x', '--[no-]extended', 'Show extended information' ) {|@extended|}
           opts.on( '-p', '--parameters', 'Show only plugin parameters in copy-paste format' ) {|@show_params|}
         end
      end

      def execute( args )
        result = @plugin_manager.plugin_infos[/#{Regexp.escape(args[0] || '')}/i]
        if result.empty?
          puts "No plugin name matches the given pattern!"
        elsif @show_params
          show_all_params( result )
        elsif result.length > 1
          show_plugins( result )
        else
          describe_plugin( result[0][0] )
        end
      end

      #######
      private
      #######

      def show_plugins( plugins )
        puts "Too many plugins match the given pattern:"
        puts

        plugins.collect {|p,i| p}.sort.each do |name|
          puts Utils.section( name, 33, 2 ) +
            Utils.format( @plugin_manager.plugin_infos.get( name, 'about', 'summary' ), 33 ).join("\n")
        end
      end

      def show_all_params( plugins )
        plugins.each do |plugin_name, data|
          params =  data['params']
          if !params.empty?
            puts Utils.bold( plugin_name )
            params.sort.each do |name, param_infos|
              print Utils.format( Utils.green( name ), 2, true ).join("\n") + ': '
              puts @plugin_manager.param( name, plugin_name ).inspect
              puts Utils.format( param_infos['desc'] ).collect {|l| '  # ' + l}.join("\n")
              puts
            end
          end

        end
      end

      def describe_plugin( plugin )
        puts "Information about #{Utils.bold(plugin)} (use -x to show extended information):"
        puts

        infos = @plugin_manager.plugin_infos
        ljust = 25

        puts Utils.headline( 'General information' )

        summary = Utils.format( infos.get( plugin, 'about', 'summary' ), ljust ).join("\n")
        puts Utils.section( 'Summary', ljust ) + summary unless summary.empty?

        author = Utils.format( infos.get( plugin, 'about', 'author' ), ljust ).join("\n")
        puts Utils.section( 'Author', ljust ) + author unless author.empty?

        deps = Array(infos.get( plugin, 'plugin', 'load_deps' )) + Array(infos.get( plugin, 'plugin', 'run_deps' ))
        puts Utils.section( 'Dependencies', ljust ) + deps.join( ', ' ) unless deps.empty?

        converter_name = infos.get( plugin, 'converts' )
        puts Utils.section( 'Converter name', ljust ) + converter_name unless converter_name.nil?

        path_patterns = (plugin =~ /^File/ ? @plugin_manager[plugin].path_patterns : nil)
        puts Utils.section( 'Path patterns', ljust ) + path_patterns.collect {|r,f| f}.inspect unless path_patterns.nil?

        tag_names = (plugin =~ /^Tag/ ? @plugin_manager[plugin].tags : nil)
        puts Utils.section( 'Tag names', ljust ) + tag_names.join(", ") unless tag_names.nil?

        puts

        params = infos.get( plugin, 'params' )
        if !params.empty?
          puts Utils.headline( 'Parameters' )
          params.sort.each do |name, param_infos|
            puts Utils.section( 'Name', ljust ) + Utils.lred( name )
            puts Utils.section( 'Value (default)', ljust ) +
              Utils.lblue( @plugin_manager.param( name, plugin ).inspect ) +
              " (" + param_infos['default'].inspect + ")"
            puts Utils.section( 'Description', ljust ) + Utils.format( param_infos['desc'], ljust ).join("\n")
            puts
          end
        end

        if @extended
          ['documentation', 'examples'].each do |section|
            text = @plugin_manager.documentation_for( plugin, section )
            unless text.strip.empty?
              puts Utils.headline( section.capitalize )
              puts
              puts text
              puts
            end
          end
        end
      end

    end

  end

end
