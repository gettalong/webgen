# -*- encoding: utf-8 -*-

module Webgen
  class Context

    # Provides methods for rendering page blocks.
    module Rendering

      # Render the named block and return the result.
      #
      # call-seq:
      #   context.render_block(block_name)<br />
      #   context.render_block(:name => block_name, :option => value, ...)
      #
      # This method uses the functionality of the content processor +blocks+ for doing the actual
      # work, so you may also want to look at Webgen::ContentProcessor::Blocks#render_block. You can
      # call this method in two ways:
      #
      # [<tt>#render_block(block_name)</tt>]
      #   Renders the block named +block_name+ of the next node in the current node chain. This is the
      #   version that most want to use since it is equivalent to the use of <tt><webgen:block
      #   name="block_name" /></tt>. It is equivalent to <tt>#render_block(:name =>
      #   block_name)</tt>.
      #
      # [<tt>#render_block(opts_hash)</tt>]
      #   This version allows the same level of control over the output as the blocks content
      #   processor. For a list of valid options have a look at the documentation of the
      #   Webgen::ContentProcessor::Blocks#render_block method!
      def render_block(name_or_hash)
        name_or_hash = {:name => name_or_hash} if name_or_hash.kind_of?(String)
        website.cache.instance('Webgen::ContentProcessor::Blocks').render_block(self, name_or_hash)
      end

    end

  end
end
