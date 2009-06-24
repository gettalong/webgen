# -*- encoding: utf-8 -*-

module Webgen

  # Namespace for all classes that know how to write out node content.
  #
  # == Implementing an output class
  #
  # Output classes know how to write rendered node data to an output location.
  #
  # An output class must respond to three methods
  #
  # [<tt>exists?(path)</tt>]
  #   Return +true+ if the output path exists.
  # [<tt>delete(path)</tt>]
  #   Delete the given output path.
  # [<tt>write(path, data, type)</tt>]
  #   Write the +data+ to the given output +path+. The parameter +data+ is either a String with the
  #   content or a Webgen::Path::SourceIO object. The parameter +type+ specifies the type of the to
  #   be written path: <tt>:file</tt> or <tt>:directory</tt>.
  # [<tt>read(path, mode = 'rb')</tt>]
  #   Return the content of the given path if it exists or raise an error otherwise. The parameter
  #   +mode+ specifies the mode in which the path should be opened and defaults to reading in binary
  #   mode.
  #
  #   It seems a bit odd that an output instance has to implement reading functionality. However,
  #   consider the case where you want webgen to render a website programmatically and *use* the
  #   output. In this case you need a way to get to content of the written files! This functionality
  #   is used, for example, in the webgui.
  #
  # == Sample Output Class
  #
  # Following is a simple but actually used (by the webgui) output class which stores the written
  # nodes in a hash in memory:
  #
  #   class MemoryOutput
  #     include Webgen::WebsiteAccess
  #
  #     attr_reader :data
  #
  #     def initialize
  #       @data = {}
  #     end
  #
  #     def exists?(path)
  #       @data.has_key?(path)
  #     end
  #
  #     def delete(path)
  #       @data.delete(path)
  #     end
  #
  #     def write(path, io, type = :file)
  #       @data[path] = [(io.kind_of?(String) ? io : io.data), type]
  #     end
  #
  #     def read(path, mode = 'rb')
  #       path = File.join('/', path)
  #       raise "No such file #{path}" unless @data[path] && @data[path].last == :file
  #       @data[path].first
  #     end
  #   end
  #
  #   WebsiteAccess.website.config.output(['MemoryOutput'])
  #
  # The last line is used to tell webgen to use this new output class instead of the default one.
  #
  module Output

    autoload :FileSystem, 'webgen/output/filesystem'

    # Returns an instance of the configured output class.
    def self.instance
      classes = (WebsiteAccess.website.cache.volatile[:classes] ||= {})
      unless classes.has_key?(:output_instance)
        klass, *args = WebsiteAccess.website.config['output']
        classes[:output_instance] = Object.constant(klass).new(*args)
      end
      classes[:output_instance]
    end

  end

end
