# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Generates valid CSS from CSS-like input, supporting variables, nesting and mixins.
  class Less

    include Webgen::Loggable

    # Convert the content in +context+ to valid CSS.
    def call(context)
      require 'less'
      context.content = ::Less.parse(context.content)
      context
    rescue LoadError
      raise Webgen::LoadError.new('less', self.class.name, context.dest_node, 'less')
    rescue ::Less::SyntaxError => e
      line = e.message.scan(/on line (\d+):/).first.first.to_i rescue nil
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node, context.ref_node, line)
    rescue ::Less::MixedUnitsError => e
      raise Webgen::RenderError.new("Can't mix different units together: #{e}",
                                    self.class.name, context.dest_node, context.ref_node)
    rescue ::Less::VariableNameError => e
      raise Webgen::RenderError.new("Variable name is undefined: #{e}",
                                    self.class.name, context.dest_node, context.ref_node)
    rescue ::Less::MixinNameError => e
      raise Webgen::RenderError.new("Mixin name is undefined: #{e}",
                                    self.class.name, context.dest_node, context.ref_node)
    rescue ::Less::ImportError => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node, context.ref_node)
    end

  end

end
