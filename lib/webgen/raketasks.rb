require 'rake'
require 'rake/tasklib'

module Webgen

  # Create a task that will generate HTML documentation using webgen.
  #
  # The DocTask will create the following targets:
  #
  # [<b>:webgen_doc</b>]
  #   Creates the documentation using webgen.
  #
  # [<b>:clobber_webgen_doc</b>]
  #   Removes the created files from the webgen documentation task.
  #
  # Example:
  #
  #   Webgen::DocTask.new( "doc" )
  #
  class DocTask < Rake::TaskLib

    # Create a documentation task for the given directory. If the output directory name is changed
    # from its normal value, specify it with the +outputDir+ parameter (has to be the whole path to
    # the output directory, e.g. if directory=doc then outputDir=doc/my_output).
    def initialize( directory, outputDir = File.join( directory, 'output' ) )
      @directory = directory
      @outputDir = outputDir
      yield self if block_given?
      if File.directory?( directory )
        define
      else
        fail "Parameter to DocTask has to be a webgen website directory"
      end
    end

    # Create the tasks defined by this task library.
    def define
      desc "Remove webgen doc products"
      task :clobber_webgen_doc do
        rm_r @outputDir rescue nil
      end

      task :clobber => [:clobber_webgen_doc]


      desc "Create the documentation using webgen"
      task :webgen_doc do
        require 'webgen/website'
        @website = Webgen::WebSite.new( @directory )
        @website.render
      end
    end

  end

end
