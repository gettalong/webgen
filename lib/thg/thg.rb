require 'thg/thgexception'
require 'optparse'
require 'util/ups'


module Thaumaturge

    Version = "0.1.0"

end

def runMain
    # load all the files in src dir and build tree
    tree = UPS::Registry['File Handler'].build_tree

    # execute tree transformer plugins
    UPS::Registry['Tree Transformer'].execute( tree )

    # generate output files
    UPS::Registry['File Handler'].write_tree( tree )
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

# everything is catched
begin

    require 'thg/configuration'

    config = UPS::Registry['Configuration']

    # specify which main method to execute
    main = method( :runMain )

    # parse options
    ARGV.options do |opts|
        opts.summary_width = 25
        opts.summary_indent = '  '
        opts.program_name = 'Thaumaturge'
        opts.version = Thaumaturge::Version

        opts.banner << "\nThaumaturge is a template based web page generator.\n\n"

        opts.on_tail( "--help", "-h", "Display this help screen" ) { puts opts; exit }
        opts.on( "--config-file FILE", "-c", String, "The configuration file which should be used" ) { |config.configFile| }
        opts.on( "--source-dir DIR", "-s", String, "The  directory from where the files are read" ) { |config.srcDirectory| }
        opts.on( "--output-dir DIR", "-o", String, "The directory where the output should go" ) { |config.outDirectory| }
        opts.on( "--list-plugins", "-p", "List all the plugins and information about them" ) { main = method( :runListPlugins ) }
        opts.on( "--list-configuration", "-e", "List all plugin configuration parameters" ) { main = method( :runListConfiguration ) }
        opts.on( "--verbosity LEVEL", "-v", Integer, "The verbosity level" ) { |config.verbosityLevel| }

        begin
            opts.parse!
        rescue RuntimeError => e
            print "Error:\n" << e.reason << ": " << e.args.join(", ") << "\n\n"
            puts opts
            exit
        end
    end

    # parse the configuration file
    config.parse_config_file

    Log4r::Logger['default'].info "Starting Thaumaturge..."

    UPS::Registry.load_plugins( File.dirname( __FILE__) + '/plugins', File.dirname( __FILE__).sub(/thg$/, '') )
    main.call

    Log4r::Logger['default'].info "Thaumaturge finished"

rescue ThgException => e
    print "An error occured:\n\t #{e.message}\n\n"
    print "Possible solution:\n\t #{e.solution}\n\n"
    print "Stack trace: #{e.backtrace.join("\n")}\n" if UPS::Registry['Configuration'].verbosityLevel >= 2
end

