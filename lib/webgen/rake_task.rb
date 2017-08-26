# -*- encoding: utf-8 -*-

#
#--
# rake_task.rb:
#
#   Define a task library for running webgen
#
# Copyright (C) 2007 Jeremy Hinegardner
#
# Tasks restructuration by Massimiliano Filacchioni
# Modifications for 0.5.0- by Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA
#
#++
#

require 'rake'
require 'rake/tasklib'

module Webgen

  ##
  # Task library to manage a webgen website.
  #
  # It is assumed that you have already used the 'webgen' command to create the website directory
  # for the site.
  #
  # == Basics
  #
  #   require 'webgen/rake_task'
  #
  #   Webgen::RakeTask.new
  #
  # == Attributes
  #
  # The attributes available in the new block are:
  #
  # [directory]
  #    the root directory of the webgen site (default <tt>Dir.pwd</tt>)
  # [config]
  #   the config block for setting additional configuration options
  # [clobber_outdir]
  #   remove webgens output directory on clobber (default +false+)
  #
  # == Tasks Provided
  #
  # The tasks provided are :
  #
  # [webgen]
  #   generate the webgen website
  # [clobber_webgen]
  #   remove all files created during generation
  #
  # == Integrate webgen in other project
  #
  # To integrate webgen tasks in another project you can use rake namespaces.  For example assuming
  # webgen's website directory is +webgen+ under the main project directory use the following code
  # fragment in project Rakefile:
  #
  #   require 'webgen/rake_task'
  #
  #   namespace :dev do
  #     Webgen::RakeTask.new do |site|
  #       site.directory = File.join(Dir.pwd, "webgen")
  #       site.clobber_outdir = true
  #       site.config_block = lambda |website|
  #         website.config['website.lang'] = 'de'
  #       end
  #     end
  #   end
  #
  #   task :clobber => ['dev:clobber_webgen']
  #
  # This will create the following tasks:
  #
  # * dev:webgen
  # * dev:clobber_webgen
  #
  # and add dev:clobber_webgen to the main clobber task.
  #
  class RakeTask < ::Rake::TaskLib

    # The directory of the webgen website.
    #
    # This would be the directory of your 'webgen.config' file. Or the parent directory of the 'src'
    # directory.
    #
    # The default value is +Dir.pwd+.
    attr_accessor :directory

    # The configuration block that is invoked when the Webgen::Website object is initialized.
    #
    # This can be used to set configuration parameters and to avoid having a 'webgen.config' file
    # lying around.
    attr_accessor :config_block

    # During the clobber, should webgen's output directory be clobbered? The default is false.
    attr_accessor :clobber_outdir

    # Create webgen tasks. You can override the task name with the parameter +name+.
    def initialize(name = 'webgen')
      @name           = name
      @directory      = Dir.pwd
      @clobber_outdir = false
      @config_block   = nil

      yield self if block_given?

      define
    end

    #######
    private
    #######

    def define # :nodoc:
      desc "Generate the webgen website"
      task @name, :verbose, :debug do |t, args|
        require 'webgen/website'
        require 'webgen/cli'
        website = Webgen::Website.new(@directory, Webgen::CLI::Logger.new($stdout), &@config_block)
        website.logger.verbose = args[:verbose] && args[:verbose].to_s == 'true'
        website.logger.level = (args[:debug] && args[:debug].to_s == 'true' ? ::Logger::DEBUG : ::Logger::INFO)
        website.execute_task(:generate_website)
      end

      task :clobber => "clobber_#{@name}".intern

      desc "Remove webgen products"
      task "clobber_#{@name}".intern do
        require 'webgen/website'
        require 'webgen/cli'
        website = Webgen::Website.new(@directory, Webgen::CLI::Logger.new($stdout), &@config_block)
        website.ext.destination.delete('/')
      end
    end

  end

end

