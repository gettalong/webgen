# -*- encoding: utf-8 -*-

module Webgen::Tag

  # Provides syntax highlighting via the +coderay+ library.
  class Coderay

    include Webgen::Tag::Base
    include Webgen::WebsiteAccess

    # Highlight the body of the block.
    def call(tag, body, context)
      require 'coderay'

      options = {}
      if param('tag.coderay.css').to_s == 'other'
        options[:css] = :class
      elsif param('tag.coderay.css').to_s == 'class'
        options[:css] = :class
        default_css_style_node = context.dest_node.resolve('/stylesheets/coderay-default.css')
        ((context.persistent[:cp_head] ||= {})[:css_file] ||= []) << context.dest_node.route_to(default_css_style_node)
        context.dest_node.node_info[:used_meta_info_nodes] << default_css_style_node.alcn
      else
        options[:css] = :style
      end
      options.merge!(:wrap => param('tag.coderay.wrap').to_sym,
                     :line_numbers => (param('tag.coderay.line_numbers') ? :inline : nil),
                     :line_number_start => param('tag.coderay.line_number_start'),
                     :tab_width => param('tag.coderay.tab_width'),
                     :bold_every => param('tag.coderay.bold_every'))

      if param('tag.coderay.process_body')
        body = website.blackboard.invoke(:content_processor, 'tags').call(context.clone(:content => body)).content
      end
      CodeRay.scan(body, param('tag.coderay.lang').to_sym).html(options)
    rescue LoadError
      raise Webgen::LoadError.new('coderay', self.class.name, context.dest_node, 'coderay')
    end

  end

end
