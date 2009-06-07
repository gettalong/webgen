# -*- encoding: utf-8 -*-

require 'erb'
require 'tempfile'
require 'fileutils'

module Webgen::Tag

  # This tag allows the creation and inclusion of complex graphics using the PGF/TikZ library of
  # LaTeX. You will need a current LaTeX distribution and the +convert+ utility from ImageMagick.
  class TikZ

    include Webgen::Tag::Base
    include Webgen::WebsiteAccess

    LATEX_TEMPLATE = <<EOF
\\nonstopmode \\documentclass{article} \\usepackage{tikz} \\pagestyle{empty}
<% if param('tag.tikz.libraries') %>
\\usetikzlibrary{<%= param('tag.tikz.libraries').join(',') %>}
<% end %>
\\begin{document}
<% if param('tag.tikz.opts') %>
\\begin{tikzpicture}[<%= param('tag.tikz.opts') %>]
<% else %>
\\begin{tikzpicture}
<% end %>
<%= body %>
\\end{tikzpicture}
\\end{document}
EOF

    # Create a graphic from the commands in the body of the tag.
    def call(tag, body, context)
      path = param('tag.tikz.path')
      path = Webgen::Path.make_absolute(context.ref_node.parent.alcn, path)

      mem_handler = website.cache.instance('Webgen::SourceHandler::Memory')
      src_path = context.ref_node.node_info[:src]
      parent = website.blackboard.invoke(:create_directories, context.ref_node.tree.root, File.dirname(path), src_path)
      params = @params

      node = website.blackboard.invoke(:create_nodes, Webgen::Path.new(path, src_path), mem_handler) do |node_path|
        mem_handler.create_node(node_path, context.ref_node.alcn) do |pic_node|
          set_params(params)
          document = ERB.new(LATEX_TEMPLATE).result(binding)
          pic_path = compile(document, File.extname(path), context)
          set_params(nil)
          if pic_path
            io = Webgen::Path::SourceIO.new { File.open(pic_path, 'rb') }
          else
            pic_node.flag(:dirty)
            nil
          end
        end
      end.first
      attrs = param('tag.tikz.img_attr').collect {|name,value| "#{name.to_s}=\"#{value}\"" }.sort.unshift('').join(' ')
      "<img src=\"#{context.dest_node.route_to(node)}\"#{attrs} />"
    end

    #######
    private
    #######

    # Compile the LaTeX +document+ and convert the resulting PDF to the correct output image format
    # specified by +ext+ (the extension needs to include the dot).
    def compile(document, ext, context)
      file = Tempfile.new('webgen-tikz')
      file.write(document)
      file.close

      FileUtils.mv(file.path, file.path + '.tex')
      cmd_prefix = "cd #{File.dirname(file.path)}; "
      output = `#{cmd_prefix} pdflatex --shell-escape -interaction=batchmode #{File.basename(file.path)}.tex`
      if $?.exitstatus != 0
        errors = output.scan(/^!(.*\n.*)/).join("\n")
        log(:error) { "There was an error creating a TikZ picture in <#{context.ref_node.alcn}>: #{errors}"}
        context.dest_node.flag(:dirty)
        nil
      else
        cmd = cmd_prefix + "pdfcrop #{File.basename(file.path)}.pdf #{File.basename(file.path)}.pdf; "
        return unless run_command(cmd, context)

        render_res, output_res = param('tag.tikz.resolution').split(' ')
        if param('tag.tikz.transparent') && ext =~ /\.png/i
          cmd = cmd_prefix +
            "gs -dSAFER -dBATCH -dNOPAUSE -r#{render_res} -sDEVICE=pngalpha -dGraphicsAlphaBits=4 -dTextAlphaBits=4 " +
            "-sOutputFile=#{File.basename(file.path)}#{ext} #{File.basename(file.path)}.pdf"
        else
          cmd = cmd_prefix + "convert -density #{render_res} #{File.basename(file.path)}.pdf #{File.basename(file.path)}#{ext}"
        end
        return unless run_command(cmd, context)

        if render_res != output_res
          cmd = cmd_prefix + "identify #{File.basename(file.path)}#{ext}"
          return unless (output = run_command(cmd, context))
          width, height = output.scan(/\s\d+x\d+\s/).first.strip.split('x').collect {|s| s.to_f * output_res.to_f / render_res.to_f }
          cmd = cmd_prefix + "convert -resize #{width}x#{height} #{File.basename(file.path)}#{ext} #{File.basename(file.path)}#{ext}"
          return unless run_command(cmd, context)
        end
        file.path + ext
      end
    end

    # Runs the command +cmd+ and returns it's output if successful or +nil+ otherwise.
    def run_command(cmd, context)
      output = `#{cmd}`
      if $?.exitstatus != 0
        log(:error) { "There was an error running a command for a TikZ picture in <#{context.ref_node.alcn}>: #{output}"}
        context.dest_node.flag(:dirty)
        nil
      else
        output
      end
    end

  end

end
