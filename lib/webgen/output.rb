module Webgen

  # Namespace for all classes that know how to write out node content.
  #
  # = Implementing an output class
  #
  # Output classes know how to write rendered node data to an output location.
  #
  # An output class must respond to three methods
  #
  # <tt>exists?(path)</tt>::
  #   Return +true+ if the output path exists.
  # <tt>delete(path)</tt>::
  #   Delete the given output path.
  # <tt>write(path, data, type)</tt>::
  #   Write the data to the given output path. The parameter +type+ specifies the type of the
  #   to be written path: <tt>:file</tt> or <tt>:directory</tt>.
  # <tt>read(path)</tt>:
  #   Return the content of the given path if it exists or raise an error otherwise.
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
