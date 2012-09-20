# -*- encoding: utf-8 -*-

require 'webgen/path'

module Webgen
  class Tag

    # This tag allows you to create and use complex graphics using the PGF/TikZ library of LaTeX. It
    # uses Webgen::ContentProcessor::Tikz for doing the hard work.
    module Tikz

      # Create a graphic (i.e. an HTML img tag) from the commands in the body of the tag.
      def self.call(tag, body, context)
        path = Webgen::Path.append(context.ref_node.parent.alcn, context[:config]['tag.tikz.path'])
        path = Webgen::Path.new(path)

        add_tikz_options!(path, context)

        node = context.website.ext.path_handler.create_secondary_nodes(path, body, 'copy', context.ref_node.alcn).first

        attrs = {'alt' => ''}.merge(context[:config]['tag.tikz.img_attr']).collect do |name, value|
          "#{name.to_s}=\"#{value}\""
        end.sort.unshift('').join(' ')
        "<img src=\"#{context.dest_node.route_to(node)}\"#{attrs} />"
      end

      # Add all needed options for Webgen::ContentProcessor::Tikz to the given path.
      def self.add_tikz_options!(path, context)
        %w[content_processor.tikz.resolution content_processor.tikz.transparent
           content_processor.tikz.libraries content_processor.tikz.opts].each do |opt|
          path.meta_info[opt] = context[:config][opt]
        end
        path.meta_info['pipeline'] = 'tikz'
      end
      private_class_method :add_tikz_options!

    end

  end
end
