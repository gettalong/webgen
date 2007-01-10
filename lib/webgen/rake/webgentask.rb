# -*- ruby -*-

#
#--
# webgentask.rb:
#
#   Define a task library for running webgen
#
# Copyright (C) 2007 Jeremy Hinegardner
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

  module Rake

    ##
    # A Rake task that generates a webgen website.
    #
    # It is assumed that you have already used the 'webgen' command
    # to create the base directory for the site.  This task is here
    # to make it easier to integrate the generation of the website
    # within the broader scope of another project.
    #
    # === Basics
    #
    #   require 'webgen/rake/webgentask'
    #
    #   Webgen::Rake::WebgenTask.new do |t|
    #       t.directory = File.join(Dir.pwd, "webgen")
    #   end
    #
    # === Attributes
    #
    # The attributes available to the task in the new block are:A
    #
    # * name              - the name of the task.  This can also be set as
    #                       a parameter to new (default :webgen)
    # * directory         - the root directory of the webgen site
    #                       (default File.join(Dir.pwd, "webgen")
    # * clobber_outdir    - remove webgens output directory on clobber
    #                       (default false)
    #
    # === Tasks Provided
    #
    # The tasks provided are :
    #
    # * webgen         - create the website
    # * clobber_webgen - remove all the files created during creation
    #
    # If the +name+ attribute is changed then the tasks are changed
    # to reflect that.  For Example:
    #
    #   Webgen::Rake::WebgenTask.new(:my_webgen) do |t|
    #       t.clobber_outdir = true
    #   end
    #
    # This will create tasks:
    #
    # * my_webgen
    # * clobber_my_webgen
    #
    class WebgenTask < ::Rake::TaskLib

      # Name of webgen task. (default is :webgen)
      attr_accessor :name

      # The directory of the webgen site.  This would be the
      # directory of your config.yaml file.  Or the parent
      # directory of the src/ directory for webgen
      #
      # The default for this is assumed to be
      #   File.join(Dir.pwd,"webgen")
      attr_accessor :directory

      # During the clobber, should webgen's output directory be
      # clobbered.  The default is false
      attr_accessor :clobber_outdir

      # Create a webgen task
      def initialize(name = :webgen)
        @name           = name
        @directory      = File.join(Dir.pwd, "webgen")
        @clobber_outdir = false

        yield self if block_given?

        @rendered_files = FileList.new

        define
      end

      def define
        desc "Run webgen"
        task @name do |t|
          Dir.chdir(@directory) do
            begin
              # some items from webgen may be sensitive to the
              # current directory when it runs

              require 'webgen/website'
              @website = Webgen::WebSite.new @directory
              @out_dir = File.expand_path(@website.param_for_plugin('Core/Configuration', 'outDir'))
              @website.render
              puts "Webgen rendered to : #{@out_dir}"

              file_list = @website.manager['Misc/RenderedFiles'].files

              # remove @out_dir from the list of rendered_files
              file_list.delete @out_dir

              @rendered_files << file_list
            rescue => e
              puts "Webgen task failed: #{e}"
              raise e
            end
          end
        end

        clobber_task = paste("clobber_",@name)

        # bit of conundrum here since we don't know what files
        # to remove until they have been generated, so we have
        # to generate all the files to remove them.
        #
        # I don't know of the right way to do this yet.
        desc "Remove webgen products"
        task clobber_task => [@name] do
          rm_rf @rendered_files
          if @clobber_outdir then
            rm_r @out_dir rescue nil
          end
        end

        task :clobber => [clobber_task]
        self
      end

    end
  end
end

