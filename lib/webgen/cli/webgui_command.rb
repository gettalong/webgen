# -*- encoding: utf-8 -*-

require 'webgen/cli'
require 'facets/kernel/silence'

# nothing to see here
module Ramaze # :nodoc:
end

module Webgen::CLI

  # The CLI command for starting the webgen webgui.
  class WebguiCommand < CmdParse::Command

    def initialize # :nodoc:
      super('webgui', false)
      self.short_desc = 'Starts the webgen webgui'
    end

    # Render the website.
    def execute(args)
      # some fixes for ramaze-2009.02
      # - fix for Windows when win32console is not installed
      # - fix for message displayed on shutdown
      # - fix for warning message
      $:.unshift File.join(Webgen.data_dir, 'webgui', 'overrides')
      require 'win32console'
      $:.shift
      silence_warnings do
        begin
          require 'ramaze'
        rescue LoadError
          puts "The Ramaze web framework which is needed for the webgui was not found."
          puts "You can install it via 'gem install ramaze --version 2009.02'"
          return
        end
      end
      def Ramaze.shutdown; # :nodoc:
      end

      Ramaze::acquire(File.join(Webgen.data_dir, 'webgui', 'controller', '*'))
      Ramaze::Log.loggers = []
      Ramaze::Global.setup do |g|
        g.root = File.join(Webgen.data_dir, 'webgui')
        g.public_root = File.join(Webgen.data_dir, 'webgui', 'public')
        g.view_root = File.join(Webgen.data_dir, 'webgui', 'view')
        g.adapter = :webrick
        g.port = 7000
      end

      puts 'Starting webgui on http://localhost:7000, press Control-C to stop'

      Thread.new do
        begin
          require 'launchy'
          sleep 2
          puts 'Launching web browser'
          Launchy.open('http://localhost:7000')
        rescue LoadError
          puts "Can't open browser because the launchy library was not found."
          puts "You can install it via 'gem install launchy'"
          puts "Please open a browser window and enter 'http://localhost:7000' into the address bar!"
        end
      end

      Ramaze.start
      puts 'webgui finished'
    end

  end

end
