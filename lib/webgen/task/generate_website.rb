# -*- encoding: utf-8 -*-

require 'benchmark'
require 'webgen/task'

module Webgen
  class Task

    # Generates the website.
    #
    # This can be called the main task of webgen.
    module GenerateWebsite

      # Main webgen task: Generate the website.
      #
      # Returns +true+ if the website has been successfully generated.
      def self.call(website)
        successful = true
        website.logger.info { "Generating website..." }
        time = Benchmark.measure do
          website.ext.path_handler.populate_tree
          if website.tree.root && !website.tree.root['passive']
            passes = website.ext.path_handler.write_tree
            if passes == 0
              website.logger.info { "Nothing has changed since the last invocation!" }
            else
              website.logger.vinfo do
                "Needed #{passes} pass#{passes == 1 ? '' : 'es'} to generate the website"
              end
            end
          else
            successful = false
            website.logger.info do
              ['No active source paths found - maybe not a webgen website?',
               'Change to a website directory and run the command again.']
            end
          end
        end
        website.logger.info { "... done in " << ('%2.2f' % time.real) << ' seconds' }
        website.save_cache if successful
        successful
      end

    end

  end
end
