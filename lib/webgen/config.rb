require 'rbconfig'

module Webgen

  VERSION = [0, 5, 0]
  AUTHOR = 'Thomas Leitner <t_leitner@gmx.at>'
  SUMMARY = "webgen is a powerful and extendable static web site generator."
  DESCRIPTION = "webgen generates static web pages from templates and page files." \
  "Page/Template files can be written in several markup languages (Textile, Markdown, ...) and " \
  "dynamically generated parts like a menu are easily included by " \
  "using ERB (embedded Ruby) or webgen's own tag system."

  # The directory below a website directory in which the source files are.
  SRC_DIR = 'src'

  # The directory below a website directory in which the plugin files are.
  PLUGIN_DIR = 'plugins'

  # Returns the data directory for webgen.
  def self.data_dir
    unless defined?( @@data_dir )
      @@data_dir =  File.expand_path( File.join( File.dirname( __FILE__ ), '..', '..', 'data', 'webgen') )

      @@data_dir = File.expand_path( File.join( Config::CONFIG["datadir"], "webgen" ) ) if !File.exists?( @@data_dir )

      raise "Could not find webgen data directory! This is a bug, report it please!" unless File.directory?( @@data_dir )
    end
    @@data_dir
  end

end
