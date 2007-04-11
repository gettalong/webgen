require 'rbconfig'

module Webgen

  VERSION = [0, 4, 3]
  AUTHOR = 'Thomas Leitner <t_leitner@gmx.at>'
  SUMMARY = "webgen is a templated based static Web site generator."
  DESCRIPTION = "webgen is a Web site generator implemented in Ruby. " \
  "It is used to generate static Web pages from templates and page " \
  "description files."

  # The directory below a website directory in which the source files are.
  SRC_DIR = 'src'

  # The directory below a website directory in which the plugin files are.
  PLUGIN_DIR = 'plugin'

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
