#
#--
#
# $Id$
#
# webgen: a template based web page generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'optparse'
require 'webgen/configuration'


module Webgen

  class WebgenError < RuntimeError

    attr_reader :solution

    def initialize( id, *args )
      super( substitute_entries( id, 0, args ) )
      @solution = substitute_entries( id, 1, args )
    end


    def substitute_entries( id, msgIndex, *args )
      args.flatten!
      @@messageMap[id][msgIndex].gsub( /%(\d+)/ ) do |match|
        args[$1.to_i].to_s
      end
    end

    private :substitute_entries

    ### Class variables and methods ###

    @@messageMap = Hash.new

    def WebgenError.add_entry( symbol, message, solution )
      raise WebgenError.new( :EXCEPTION_SYMBOL_IS_DEFINED, symbol, caller[0] ) if @@messageMap.has_key? symbol
      @@messageMap[symbol] = [message, solution]
    end

    WebgenError.add_entry :EXCEPTION_SYMBOL_IS_DEFINED,
       "the symbol %0 is already defined (%1)",
       "change the name of the symbol"

  end


  class WebgenMain

    def main( cmdOptions )
      # everything is catched
      begin
        # specify which main method to execute
        main = parse_options cmdOptions

        # parse the configuration file
        UPS::Registry['Configuration'].parse_config_file
        UPS::Registry['Configuration'].load_file_outputter if main == method( :runMain )

        UPS::Registry.load_plugins( File.dirname( __FILE__) + '/plugins', File.dirname( __FILE__).sub(/webgen$/, '') )
        main.call
      rescue WebgenError => e
        print "An error occured:\n\t #{e.message}\n\n"
        print "Possible solution:\n\t #{e.solution}\n\n"
        print "Stack trace: #{e.backtrace.join("\n")}\n" if UPS::Registry['Configuration'].verbosityLevel <= 1
      end
    end


    def parse_options( cmdOptions )
      config = UPS::Registry['Configuration']
      main = method( :runMain )

      opts = OptionParser.new do |opts|
        opts.summary_width = 25
        opts.summary_indent = '  '

        opts.banner = "Usage: webgen [options]\n#{Webgen::Description}"

        opts.separator ""
        opts.separator "Configuration options:"

        opts.on( "--config-file FILE", "-c", String, "The configuration file which should be used" ) { |config.configFile| }
        opts.on( "--source-dir DIR", "-s", String, "The directory from where the files are read" ) { |config.srcDirectory| }
        opts.on( "--output-dir DIR", "-o", String, "The directory where the output should go" ) { |config.outDirectory| }
        opts.on( "--verbosity LEVEL", "-v", Integer, "The verbosity level" ) { |config.verbosityLevel| }

        opts.separator ""
        opts.separator "Other options:"

        opts.on( "--list-plugins", "-p", "List all the plugins and information about them" ) { main = method( :runListPlugins ) }
        opts.on( "--list-configuration", "-e", "List all plugin configuration parameters" ) { main = method( :runListConfiguration ) }
        opts.on_tail( "--help", "Display this help screen" ) { puts opts; exit }
        opts.on_tail( "--version", "Show version" ) do
          puts "Webgen #{Webgen::Version}"
          exit
        end
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
      Log4r::Logger['default'].info "Starting Webgen..."

      # load all the files in src dir and build tree
      tree = UPS::Registry['File Handler'].build_tree

      # execute tree transformer plugins
      UPS::Registry['Tree Walker'].execute( tree )

      # generate output files
      UPS::Registry['File Handler'].write_tree( tree )

      Log4r::Logger['default'].info "Webgen finished"
    end


    def runListPlugins
      print "List of loaded plugins:\n"

      tagPlugins = []
      fileHandlerPlugins = []
      treeWalkers = []
      others = []

      UPS::Registry.each do |name, plugin|
        if plugin.class.name =~ /^Tags::/
          tagPlugins.push plugin
        elsif plugin.class.name =~ /^FileHandlers::/
          fileHandlerPlugins.push plugin
        elsif plugin.class.name =~ /^TreeWalkers::/
          treeWalkers.push plugin
        else
          others.push plugin
        end
      end

      showProc = proc do |caption, array|
        print "\n  #{caption}:\n";
        array.sort do |a, b|
          a.class.const_get( :NAME ) <=>  b.class.const_get( :NAME )
        end.each do |plugin|
          print "    - #{plugin.class.const_get :NAME}:".ljust(30) +"#{plugin.class.const_get :SHORT_DESC}\n"
        end
      end

      showProc.call( 'File handler plugins', fileHandlerPlugins )
      showProc.call( 'Tag plugins', tagPlugins )
      showProc.call( 'Tree walker plugins', treeWalkers )
      showProc.call( 'Other plugins', others )
    end


    def runListConfiguration
      print "List of configuration parameters:\n\n"
      params = UPS::Registry['Configuration'].configParams
      params.sort.each do |name, config|
        print "  - #{name}\n"
        config.each do |paramValue|
          print "      #{paramValue[0]}:".ljust(30) +"#{paramValue[1].inspect} (#{paramValue[2].inspect})\n"
        end
	print "\n"
      end
    end

  end

end
