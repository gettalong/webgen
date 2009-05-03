# -*- encoding: utf-8 -*-

require 'webgen/cli'
require 'facets/kernel/silence'

module Webgen::CLI

  # The CLI command for starting the webgen webgui.
  class WebguiCommand < CmdParse::Command

    def initialize # :nodoc:
      super('webgui', false)
      self.short_desc = 'Starts the webgen webgui'
    end

    # Render the website.
    def execute(args)
      # some fixes for ramaze-2009.04
      # - fix for Windows when win32console is not installed
      # - fix for message displayed on shutdown
      # - fix for warning message
      $:.unshift File.join(Webgen.data_dir, 'webgui', 'overrides')
      require 'win32console'
      $:.shift
      silence_warnings do
        begin
          require 'ramaze/snippets/object/__dir__'
          Object.__send__(:include, Ramaze::CoreExtensions::Object)
          require 'ramaze'
        rescue LoadError
          puts "The Ramaze web framework which is needed for the webgui was not found."
          puts "You can install it via 'gem install ramaze --version 2009.04'"
          return
        end
      end
      def Ramaze.shutdown; # :nodoc:
      end

      require File.join(Webgen.data_dir, 'webgui', 'app.rb')
      Ramaze::Log.loggers = []
      Ramaze.options[:middleware_compiler]::COMPILED[:dev].middlewares.delete_if do |app, args, block|
        app == Rack::CommonLogger
      end

      puts 'Starting webgui on http://localhost:7000, press Control-C to stop'

      Thread.new do
        begin
          require 'launchy'
          sleep 1
          puts 'Launching web browser'
          Launchy.open('http://localhost:7000')
        rescue LoadError
          puts "Can't open browser because the launchy library was not found."
          puts "You can install it via 'gem install launchy'"
          puts "Please open a browser window and enter 'http://localhost:7000' into the address bar!"
        end
      end

      Ramaze.start(:adapter => :webrick, :port => 7000, :file => File.join(Webgen.data_dir, 'webgui', 'app.rb'))
      puts 'webgui finished'
    end

  end

end
