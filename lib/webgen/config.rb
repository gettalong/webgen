#
#--
#
# $Id: config.rb 621 2007-02-28 09:45:30Z thomas $
#
# webgen: template based static website generator
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
