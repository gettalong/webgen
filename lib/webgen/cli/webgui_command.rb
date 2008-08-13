require 'webgen/cli'

module Webgen::CLI

  # The CLI command for starting the webgen webgui.
  class WebguiCommand < CmdParse::Command

    def initialize # :nodoc:
      super('webgui', false)
      self.short_desc = 'Starts the webgen webgui'
    end

    # Render the website.
    def execute(args)
      # some fixes for ramaze-2008.06
      # - fix for Windows bug when win32console is not installed
      # - fix for message displayed on shutdown
      $:.unshift File.join(Webgen.data_dir, 'webgui', 'overrides')
      require 'win32console'
      $:.shift
      require 'ramaze'
      Ramaze::Log.loggers = []
      def Ramaze.shutdown; end

      acquire Webgen.data_dir/:webgui/:controller/'*'
      Ramaze::Global.setup do |g|
        g.root = Webgen.data_dir/:webgui
        g.public_root = Webgen.data_dir/:webgui/:public
        g.view_root = Webgen.data_dir/:webgui/:view
        g.adapter = :webrick
        g.port = 7000
      end

      puts 'Starting webgui on http://localhost:7000, press Control-C to stop'
      Thread.new do
        sleep 2
        puts 'Launching web browser'
        require 'launchy'
        Launchy.open('http://localhost:7000')
      end

      Ramaze.start
      puts 'webgui finished'
    end

  end

end
