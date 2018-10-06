# -*- encoding: utf-8 -*-

require 'erb'
require 'tempfile'
require 'fileutils'
require 'webgen/content_processor'
require 'webgen/utils/external_command'

Webgen::Utils::ExternalCommand.ensure_available!('pdflatex', '-v')
Webgen::Utils::ExternalCommand.ensure_available!('gs', '-v')
Webgen::Utils::ExternalCommand.ensure_available!('convert', '-version')
Webgen::Utils::ExternalCommand.ensure_available!('identify', '-version')

module Webgen
  class ContentProcessor

    # Uses LaTeX and the TikZ library for creating images from LaTeX code.
    module Tikz

      # Process the content with LaTeX to generate a TikZ image.
      def self.call(context)
        prepare_options(context)
        context.content = context.render_block(:name => 'content',
                                               :chain => [context.website.tree[context['content_processor.tikz.template']]])
        context.content = File.binread(use_cache_or_compile(context))
        context
      end

      # Collect the necessary options and save them in the context object.
      def self.prepare_options(context)
        %w[content_processor.tikz.resolution content_processor.tikz.transparent
           content_processor.tikz.libraries content_processor.tikz.opts
           content_processor.tikz.template content_processor.tikz.engine].each do |opt|
          context[opt] = context.content_node[opt] || context.website.config[opt]
        end
        context['data'] = context.content
      end
      private_class_method :prepare_options

      # Checks whether a cached version exists and if it is usable. If not, the LaTeX document is
      # compiled.
      def self.use_cache_or_compile(context)
        cwd = context.website.tmpdir('content_processor.tikz')
        FileUtils.mkdir_p(cwd)

        tex_file = File.join(cwd, context.dest_node.dest_path.tr('/', '_').sub(/\..*?$/, '.tex'))
        basename = File.basename(tex_file, '.tex')
        ext = File.extname(context.dest_node.dest_path)
        image_file = tex_file.sub(/\.tex$/, ext)

        if !cache_usable?(context, tex_file, image_file)
          compile(context, cwd, tex_file, basename, ext)
          save_cache(context, tex_file)
        end

        image_file
      end
      private_class_method :use_cache_or_compile

      # Compile the LaTeX document stored in the Context and convert the resulting PDF to the
      # correct output image format specified by context[:ext] (the extension needs to include the
      # dot).
      #
      # Returns the path to the created image.
      def self.compile(context, cwd, tex_file, basename, ext)
        render_res, output_res = context['content_processor.tikz.resolution'].split(' ')

        engine = context['content_processor.tikz.engine']
        File.write(tex_file, context.content)
        execute("#{engine} -shell-escape -interaction=nonstopmode -halt-on-error #{basename}.tex", cwd, context) do |_status, stdout, stderr|
          errors = (stdout+stderr).scan(/^!(.*\n.*)/).join("\n")
          raise Webgen::RenderError.new("Error while parsing TikZ picture commands with #{engine}: #{errors}",
                                        'content_processor.tikz', context.dest_node, context.ref_node)
        end

        if context['content_processor.tikz.transparent'] && ext =~ /\.png/i
          cmd = "gs -dSAFER -dBATCH -dNOPAUSE -r#{render_res} -sDEVICE=pngalpha -dGraphicsAlphaBits=4 " +
            "-dTextAlphaBits=4 -sOutputFile=#{basename}#{ext} #{basename}.pdf"
        elsif ext =~ /\.svg/i
          # some installations of ghostscript (`gs`) also have a svg output device, but pdf2svg
          # is a safer bet.
          cmd = "pdf2svg #{basename}.pdf #{basename}.svg"
        else
          cmd = "convert -density #{render_res} #{basename}.pdf #{basename}#{ext}"
        end
        execute(cmd, cwd, context)

        # resizing doesn't really make sense on a vector graphic.
        unless ext =~ /\.svg/i
          if render_res != output_res
            _status, stdout, _stderr = execute("identify #{basename}#{ext}", cwd, context)
            width, height = stdout.scan(/\s\d+x\d+\s/).first.strip.split('x').collect do |s|
              s.to_f * output_res.to_f / render_res.to_f
            end
            execute("convert -resize #{width}x#{height} #{basename}#{ext} #{basename}#{ext}", cwd, context)
          end
        end
      end
      private_class_method :compile

      # Save cache data so that it is possible to use it the next time.
      def self.save_cache(context, tex_file)
        File.write(cache_file(tex_file), cache_data(context))
      end
      private_class_method :save_cache

      # Check if the content of the LaTeX document or the used options have changed.
      def self.cache_usable?(context, tex_file, image_file)
        cfile = cache_file(tex_file)
        File.exist?(image_file) && File.exist?(cfile) && File.binread(cfile) == cache_data(context)
      end
      private_class_method :cache_usable?

      # The data that should be written to the cache file.
      def self.cache_data(context)
        ("" << context.content <<
          "\n" << context['content_processor.tikz.resolution'].to_s <<
          "\n" << context['content_processor.tikz.transparent'].to_s <<
          "\n" << context['content_processor.tikz.libraries'].to_s <<
          "\n" << context['content_processor.tikz.opts'].to_s <<
          "\n" << context['content_processor.tikz.template'].to_s).force_encoding('BINARY')
      end
      private_class_method :cache_data

      # Return the name of the cache file for the give LaTeX file.
      def self.cache_file(tex_file)
        tex_file.sub(/\.tex$/, ".cache")
      end
      private_class_method :cache_file

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
                                          'content_processor.tikz', context.dest_node, context.ref_node)
          end
        end
        [status, stdout, stderr]
      end
      private_class_method :execute

    end

  end
end
