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

  class Color

    @@colors = {:bold => [0, 1], :green => [0, 32], :lblue => [1, 34], :lred => [1, 31], :reset => [0, 0]}

    def Color.colorify
      @@colors.each do |color, values|
        module_eval <<-EOF
        def Color.#{color.to_s}
        "\e[#{values[0]};#{values[1]}m"
        end
        EOF
      end
    end

    def Color.method_missing( id )
      ''
    end

  end

  class WebgenMain

    def main( cmdOptions )
      # specify which main method to execute
      main = parse_options cmdOptions

      # parse the configuration file
      UPS::Registry['Configuration'].parse_config_file

      UPS::Registry.load_plugins( File.dirname( __FILE__) + '/plugins', File.dirname( __FILE__).sub(/webgen$/, '') )

      Color.colorify if $stdout.isatty

      main.call
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

        opts.on( "--config-file FILE", "-C", String, "The configuration file which should be used" ) { |config.configFile| }
        opts.on( "--source-dir DIR", "-S", String, "The directory from where the files are read" ) { |config.srcDirectory| }
        opts.on( "--output-dir DIR", "-O", String, "The directory where the output should go" ) { |config.outDirectory| }
        opts.on( "--verbosity LEVEL", "-V", Integer, "The verbosity level" ) { |config.verbosityLevel| }
        opts.on( "--[no-]logfile", "-L", "Use log file" ) { |logfile| UPS::Registry['Configuration'].load_file_outputter if logfile }

        opts.separator ""
        opts.separator "Other options:"

        opts.on( "--list-plugins", "-p", "List all the plugins and information about them" ) { main = method( :runListPlugins ) }
        opts.on( "--list-configuration", "-c", "List all plugin configuration parameters" ) { main = method( :runListConfiguration ) }
        opts.on_tail( "--help", "Display this help screen" ) { puts opts; exit }
        opts.on_tail( "--version", "-v", "Show version" ) do
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

      headers = {
        'FileHandlers' => 'File handler plugins',
        'Tags' => 'Tag plugins',
        'TreeWalkers' => 'Tree walker plugins'
      }
      headers.default = 'Other plugins'

      ljustlength = 30 + Color.green.length + Color.reset.length
      header = ''
      UPS::Registry.sort { |a, b| a[1].class.name <=> b[1].class.name }.each do |name, plugin|
        newHeader = headers[plugin.class.name[/^.*?(?=::)/]]
        unless newHeader == header
          print "\n  #{Color.bold}#{newHeader}#{Color.reset}:\n";
          header = newHeader
        end
        print "    - #{Color.green}#{plugin.class.const_get :NAME}#{Color.reset}:".ljust(ljustlength) +"#{plugin.class.const_get :SHORT_DESC}\n"
      end
    end


    def runListConfiguration
      print "List of configuration parameters:\n\n"
      params = UPS::Registry['Configuration'].configParams
      ljustlength = 20 + Color.green.length + Color.reset.length
      params.sort.each do |name, config|
        print "  #{Color.bold}#{name}#{Color.reset}:\n"
        config.sort.each do |key, item|
          print "    #{Color.green}Parameter:#{Color.reset}".ljust(ljustlength)
          puts Color.lred + item.name + Color.reset + " = " + Color.lblue +  item.value.inspect + Color.reset + " (" + item.defaultValue.inspect + ")"
          puts "    #{Color.green}Description:#{Color.reset}".ljust(ljustlength) + item.description
          print "\n"
        end
        print "\n"
      end
    end

  end

end
