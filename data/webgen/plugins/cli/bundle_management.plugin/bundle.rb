require 'cmdparse'

module Cli

  module Commands

    class Bundle < CmdParse::Command

      def initialize
        super( 'bundle', true )
      end

      def init_plugin
        self.short_desc = @plugin_manager.plugin_infos.get( plugin_name, 'about', 'summary' )
        add_command( Install.new( @plugin_manager) )
        add_command( Remove.new( @plugin_manager) )
        add_command( Package.new( @plugin_manager) )
        add_command( List.new( @plugin_manager) )
        add_command( Update.new( @plugin_manager) )
      end



      class Install < CmdParse::Command

        def initialize( plugin_manager )
          super( 'install', false )
          @plugin_manager = plugin_manager

          @target = :website
          @version = nil

          self.short_desc = 'Install a webgen plugin bundle from a repository'
          self.options = CmdParse::OptionParserWrapper.new do |opts|
            opts.separator "Options:"
            opts.on( '-v', '--version VERSION', String, 'The version of the bundle to install (default: latest)' ) {|@version|}
            opts.on( '-t', '--target TARGET', [:website, :home], 'The target location: website (default), home' ) {|@target|}
          end
        end

        def execute( args )
          if args.length != 1
            puts 'You have to specify exactly one plugin bundle to install!'
            return
          end
          @plugin_manager['Support/BundleManager'].install_bundle( args.shift, @version, @target ) do |result, message|
            print "Installation... "
            if result == :failed
              puts Utils.red('failed') + ' - reason: ' + message
            else
              puts Utils.green('succeeded')
            end
          end
        end

      end



      class Remove < CmdParse::Command

        def initialize( plugin_manager )
          super( 'remove', false )
          @plugin_manager = plugin_manager

          self.short_desc = 'Remove an installed plugin bundle'
        end

        def execute( args )
          if args.length != 1
            puts 'You have to specify exactly one plugin bundle name to remove!'
            return
          end
          @plugin_manager['Support/BundleManager'].remove_bundle( args.shift ) do |result, message|
            print "Removing bundle... "
            if result == :failed
              puts Utils.red('failed') + ' - reason: ' + message
            else
              puts Utils.green('succeeded')
            end
          end
        end

      end



      class Package < CmdParse::Command

        def initialize( plugin_manager )
          super( 'package', false )
          @plugin_manager = plugin_manager

          @repository = nil

          self.short_desc = 'Create a compressed plugin bundle package for distribution'
          self.options = CmdParse::OptionParserWrapper.new do |opts|
            opts.separator "Options:"
            opts.on( '-r', '--repository REPO', String, 'Path to the repository which should be updated' ) {|@repository|}
          end
        end

        def execute( args )
          if args.length == 0
            puts "You need to specify at least one plugin bundle path!"
            return
          end
          if @repository.nil?
            puts "You need to specify the to-be-update repository using the -r switch!"
            return
          end
          args.each do |path|
            print Utils.section( "Creating bundle for #{path}...", 55, 0, :none )
            begin
              @plugin_manager['Support/BundleManager'].package_bundle( path, @repository )
            rescue
              puts Utils.red('failed') + ' - reason: ' + $!.message
            else
              puts Utils.green('succeeded')
            end
          end
        end

      end



      class List < CmdParse::Command

        def initialize( plugin_manager )
          super( 'list', false )
          @plugin_manager = plugin_manager

          @show_plugins = false
          @show_resources = false

          self.short_desc = 'List the available plugin bundles'
          self.options = CmdParse::OptionParserWrapper.new do |opts|
            opts.separator "Options:"
            opts.on( '-p', '--show-plugins', 'Include information on plugins') {|@show_plugins|}
            opts.on( '-r', '--show-resources', 'Include information on resources') {|@show_resources|}
          end
        end

        def execute( args )
          repos = @plugin_manager['Support/BundleManager'].repositories

          puts "Available plugin repositories:"
          puts

          repos.sort.each do |repo|
            print Utils.section( repo.uri, 0, 2 ) + ' (' + repo.bundles.size.to_s + ' plugin bundles)   '
            puts Utils.format( repo.description, 8 ).join("\n")
            ljust = 25

            repo.bundles.sort.each do |bundle|
              next unless VersionNumber.constraint_lambda( bundle.webgen_version ).call( VersionNumber.new( Webgen::VERSION ) )
              puts Utils.format( Utils.bold(bundle.name) + ' (' + bundle.version + ', ' + bundle.status.to_s + '):', 4, true )
              puts Utils.format( bundle.summary, 6, true ) unless bundle.summary.to_s.empty?
              print_plugin_infos( bundle.plugins, ljust, 6 ) if @show_plugins
              print_resource_infos( bundle.resources, ljust, 6 )if @show_resources
              puts
            end
          end
        end

        def print_plugin_infos( plugins, ljust, indent )
          plugins.sort.each do |plugin|
            puts Utils.section( plugin.name + ':', ljust, indent, :bold )

            summary = Utils.format( plugin.summary.to_s, ljust ).join("\n")
            puts Utils.section( 'Summary', ljust, indent + 2 ) + summary unless summary.empty?

            description = Utils.format( plugin.description.to_s, ljust ).join("\n")
            puts Utils.section( 'Description', ljust, indent + 2 ) + description unless description.empty?

            author = Utils.format( plugin.author.to_s, ljust ).join("\n")
            puts Utils.section( 'Author', ljust, indent + 2 ) + author unless author.empty?
          end
        end

        def print_resource_infos( resources, ljust, indent )
          puts Utils.section( 'Resources:', ljust, indent, :bold )
          resources.sort.each do |res|
            puts Utils.section( res.name, ljust, indent + 2 ) + Utils.format( res.description, ljust ).join("\n")
          end
        end

      end



      class Update < CmdParse::Command

        def initialize( plugin_manager )
          super( 'update', false )
          @plugin_manager = plugin_manager

          @update = false

          self.short_desc = 'Update information about available plugin bundles'
        end

        def execute( args )
          print_status = lambda do |status, message|
            if status == :failed
              puts Utils.red('failed') + ' - reason: ' + message
            else
              puts Utils.green('succeeded')
            end
          end
          @plugin_manager['Support/BundleManager'].update_repositories do |what, status, message|
            if what == :repos
              print Utils.section( "Updating the plugin repository list... ", 55, 0, :none )
              print_status.call( status, message )
            else
              print Utils.section( "Updating #{what}... ", 55, 0, :none )
              print_status.call( status, message )
            end
          end
        end

      end



    end

  end

end
