# -*- encoding: utf-8 -*-

# -*- ruby -*-
#
#--
# webgentask.rb:
#
#   Define a task library for running webgen
#
# Copyright (C) 2007 Jeremy Hinegardner
#
# Tasks restructuration by Massimiliano Filacchioni
# Modifications for 0.5.0 by Thomas Leitner
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
  #   require 'webgen/webgentask'
  #
  #   Webgen::WebgenTask.new
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
  #   render the webgen website
  # [clobber_webgen]
  #   remove all the files created during generation
  #
  # == Integrate webgen in other project
  #
  # To integrate webgen tasks in another project you can use rake namespaces.  For example assuming
  # webgen's site directory is +webgen+ under the main project directory use the following code
  # fragment in project Rakefile:
  #
  #   require 'webgen/webgentask'
  #
  #   namespace :dev do
  #     Webgen::WebgenTask.new do |site|
  #       site.directory = File.join(Dir.pwd, "webgen")
  #       site.clobber_outdir = true
  #       site.config_block = lambda |config|
  #         config['website.lang'] = 'de'
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
  class WebgenTask < ::Rake::TaskLib

    # The directory of the webgen website. This would be the directory of your <tt>config.yaml</tt>
    # file. Or the parent directory of the <tt>src/</tt> directory for webgen.
    #
    # The default for this is assumed to be <tt>Dir.pwd</tt>
    attr_accessor :directory

    # The configuration block that is invoked when the Webgen::Website object is initialized. This
    # can be used to set configuration parameters and to avoid having a <tt>config.yaml</tt> file
    # lying around.
    attr_accessor :config_block

    # During the clobber, should webgen's output directory be clobbered. The default is false.
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
      desc "Render the webgen website"
      task @name, :verbosity, :log_level do |t, args|
        require 'webgen/website'
        website = Webgen::Website.new(@directory, Webgen::Logger.new($stdout), &@config_block)
        website.logger.verbosity = args[:verbosity].to_s.intern unless args[:verbosity].to_s.empty?
        website.logger.level = args[:log_level].to_i if args[:log_level]
        website.render
      end

      task :clobber => paste('clobber_', @name)

      desc "Remove webgen products"
      task paste('clobber_', @name) do
        require 'webgen/website'
        website = Webgen::Website.new(@directory, Webgen::Logger.new($stdout), &@config_block)
        website.clean(@clobber_outdir)
      end
    end

  end

end

