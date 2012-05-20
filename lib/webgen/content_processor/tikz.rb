# -*- encoding: utf-8 -*-

require 'erb'
require 'tempfile'
require 'webgen/content_processor'
require 'webgen/utils/external_command'

Webgen::Utils::ExternalCommand.ensure_available!('pdflatex', '-v')
Webgen::Utils::ExternalCommand.ensure_available!('pdfcrop', '--version')
Webgen::Utils::ExternalCommand.ensure_available!('gs', '-v')
Webgen::Utils::ExternalCommand.ensure_available!('convert', '-version')
Webgen::Utils::ExternalCommand.ensure_available!('identify', '-version')

module Webgen
  class ContentProcessor

    # Uses LaTeX and the TikZ library for creating images from LaTeX code.
    module Tikz

      LATEX_TEMPLATE = <<EOF
\\nonstopmode \\documentclass{article} \\usepackage{tikz} \\pagestyle{empty}
<% if context['content_processor.tikz.libraries'] %>
\\usetikzlibrary{<%= context['content_processor.tikz.libraries'].join(',') %>}
<% end %>
\\begin{document}
\\begin{tikzpicture}[<%= context['content_processor.tikz.opts'] %>]
<%= context.content %>
\\end{tikzpicture}
\\end{document}
EOF

      # Process the content with LaTeX to generate a TikZ image.
      def self.call(context)
        prepare_options(context)
        context.content = ERB.new(LATEX_TEMPLATE).result(binding)
        context.content = File.binread(compile(context))
        context
      end

      # Collect the necessary options and save them in the context object.
      def self.prepare_options(context)
        %w[content_processor.tikz.resolution content_processor.tikz.transparent
           content_processor.tikz.libraries content_processor.tikz.opts].each do |opt|
          context[opt] = context.content_node[opt] || context.website.config[opt]
        end
      end
      private_class_method :prepare_options

      # Compile the LaTeX document stored in the Context and convert the resulting PDF to the
      # correct output image format specified by context[:ext] (the extension needs to include the
      # dot).
      #
      # Returns the path to the created image.
      def self.compile(context)
        tempfile = Tempfile.open(['webgen-tikz', '.tex'])
        tempfile.write(context.content)
        tempfile.close

        cwd = File.dirname(tempfile.path)
        file = File.basename(tempfile.path, '.tex')
        ext = File.extname(context.dest_node.dest_path)
        render_res, output_res = context['content_processor.tikz.resolution'].split(' ')

        execute("pdflatex --shell-escape -interaction=batchmode #{file}.tex", cwd, context) do |status, stdout, stderr|
          errors = stderr.scan(/^!(.*\n.*)/).join("\n")
          raise Webgen::RenderError.new("Error while parsing TikZ picture commands with PDFLaTeX: #{errors}",
                                        self.name, context.dest_node, context.ref_node)
        end

        execute("pdfcrop #{file}.pdf #{file}.pdf", cwd, context)

        if context['content_processor.tikz.transparent'] && ext =~ /\.png/i
          cmd = "gs -dSAFER -dBATCH -dNOPAUSE -r#{render_res} -sDEVICE=pngalpha -dGraphicsAlphaBits=4 " +
            "-dTextAlphaBits=4 -sOutputFile=#{file}#{ext} #{file}.pdf"
        else
          cmd = "convert -density #{render_res} #{file}.pdf #{file}#{ext}"
        end
        execute(cmd, cwd, context)

        if render_res != output_res
          status, stdout, stderr = execute("identify #{file}#{ext}", cwd, context)
          width, height = stdout.scan(/\s\d+x\d+\s/).first.strip.split('x').collect do |s|
            s.to_f * output_res.to_f / render_res.to_f
          end
          execute("convert -resize #{width}x#{height} #{file}#{ext} #{file}#{ext}", cwd, context)
        end
        File.join(cwd, file + ext)
      end
      private_class_method :compile

      # Execute the command +cmd+ in the working directory +cwd+.
      #
      # If the exit status is not zero, yields to the given block if one is given, or raises an error
      # otherwise.
      #
      # Returns [status, stdout, stderr]
      def self.execute(cmd, cwd, context)
        status, stdout, stderr = systemu(cmd, :cwd => cwd)
        if status.exitstatus != 0
          if block_given?
            yield(status, stdout, stderr)
          else
            raise Webgen::RenderError.new("Error while running a command for a TikZ picture: #{stdout + "\n" + stderr}",
                                          self.name, context.dest_node, context.ref_node)
          end
        end
        [status, stdout, stderr]
      end
      private_class_method :execute

    end

  end
end
