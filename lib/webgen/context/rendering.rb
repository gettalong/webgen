# -*- encoding: utf-8 -*-

require 'webgen/content_processor/blocks'

module Webgen
  class Context

    # Provides methods for rendering page blocks.
    module Rendering

      # Render the named block and return the result.
      #
      # call-seq:
      #   context.render_block(block_name)
      #   context.render_block(:name => block_name, :option => value, ...)
      #
      # This method uses the functionality of Webgen::ContentProcessor::Blocks for doing the actual
      # work, so you may also want to look at Webgen::ContentProcessor::Blocks.render_block. You can
      # call this method in two ways:
      #
      # [#render_block(block_name)]
      #   Renders the block named +block_name+ of the next node in the current node chain. This is
      #   the version that most want to use since it is equivalent to the use of '<webgen:block
      #   name="block_name" />'. It is also equivalent to '#render_block(:name => block_name)'.
      #
      # [#render_block(opts_hash)]
      #   This version allows the same level of control over the output as the blocks content
      #   processor. For a list of valid options have a look at the documentation of the
      #   Webgen::ContentProcessor::Blocks.render_block method!
      #
      def render_block(name_or_hash)
        name_or_hash = {:name => name_or_hash} if name_or_hash.kind_of?(String)
        Webgen::ContentProcessor::Blocks.render_block(self, name_or_hash)
      end

    end

  end
end
