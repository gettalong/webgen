require 'thg/thgexception'
require 'optparse'
require 'thg/configuration'


module Thaumaturge

    class ThgMain

        def main( cmdOptions )
            # everything is catched
            begin
                # specify which main method to execute
                main = parse_options cmdOptions

                # parse the configuration file
                UPS::Registry['Configuration'].parse_config_file
                UPS::Registry['Configuration'].load_file_outputter if main == method( :runMain )

                UPS::Registry.load_plugins( File.dirname( __FILE__) + '/plugins', File.dirname( __FILE__).sub(/thg$/, '') )
                main.call
            rescue ThgException => e
                print "An error occured:\n\t #{e.message}\n\n"
                print "Possible solution:\n\t #{e.solution}\n\n"
                print "Stack trace: #{e.backtrace.join("\n")}\n" if UPS::Registry['Configuration'].verbosityLevel <= 1
            end
        end


        def parse_options( cmdOptions )
            config = UPS::Registry['Configuration']
            main = method( :runMain )

            # parse options
            opts = OptionParser.new do |opts|
                opts.summary_width = 25
                opts.summary_indent = '  '
                opts.program_name = Thaumaturge::NAME
                opts.version = Thaumaturge::VERSION

                opts.banner << "\n#{Thaumaturge::DESCRIPTION}\n\n"

                opts.on_tail( "--help", "-h", "Display this help screen" ) { puts opts; exit }
                opts.on( "--config-file FILE", "-c", String, "The configuration file which should be used" ) { |config.configFile| }
                opts.on( "--source-dir DIR", "-s", String, "The  directory from where the files are read" ) { |config.srcDirectory| }
                opts.on( "--output-dir DIR", "-o", String, "The directory where the output should go" ) { |config.outDirectory| }
                opts.on( "--list-plugins", "-p", "List all the plugins and information about them" ) { main = method( :runListPlugins ) }
                opts.on( "--list-configuration", "-e", "List all plugin configuration parameters" ) { main = method( :runListConfiguration ) }
                opts.on( "--verbosity LEVEL", "-v", Integer, "The verbosity level" ) { |config.verbosityLevel| }
            end

            begin
                opts.parse! cmdOptions
            rescue RuntimeError => e
                print "Error:\n" << e.reason << ": " << e.args.join(", ") << "\n\n"
                puts opts
                exit
            end

            main
        end

        def runMain
            Log4r::Logger['default'].info "Starting Thaumaturge..."

            # load all the files in src dir and build tree
            tree = UPS::Registry['File Handler'].build_tree

            # execute tree transformer plugins
            UPS::Registry['Tree Transformer'].execute( tree )

            # generate output files
            UPS::Registry['File Handler'].write_tree( tree )

            Log4r::Logger['default'].info "Thaumaturge finished"
        end


        def runListPlugins
            print "List of loaded plugins:\n"
            UPS::Registry.sort.each do |entry|
                print "  * #{entry[0]}:".ljust(30) +"#{entry[1].class.const_get :SHORT_DESC}\n"
            end
        end


        def runListConfiguration
            print "List of configuration parameters:\n"
            params = UPS::Registry['Configuration'].configParams
            params.sort.each do |entry|
                print "  * #{entry[0]}\n"
                entry[1].each do |paramValue|
                    print "      #{paramValue[0]}:".ljust(30) +"#{paramValue[1].inspect} | #{paramValue[2].inspect}\n"
                end
            end
        end

    end

end
