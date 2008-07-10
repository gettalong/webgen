require 'webgen/languages'

module Webgen

  # A path object provides information about a specific path as well as methods for accessing its
  # content.
  #
  # A webgen source class needs to derive a specialized path class from this class and implement an
  # approriate #changed? method that returns +true+ if the path's content has changed since the last
  # webgen run.
  class Path

    # Helper class for easy access to the content of a path.
    class SourceIO

      # Create a new SourceIO object. A block has to be specified that returns an IO object.
      def initialize(&block)
        @block = block
        raise ArgumentError, 'Need to provide a block which returns an IO object' if @block.nil?
      end

      # Provide direct access to the wrapped IO object.
      def stream
        io = @block.call
        yield(io)
      ensure
        io.close
      end

      # Return the content of the wrapped IO object as string.
      def data
        stream {|io| io.read}
      end

    end


    include Comparable

    # The full source path.
    attr_accessor :path

    # The basename part of the path.
    attr_accessor :basename

    # The directory part of the path.
    attr_accessor :directory

    # The canonical name without the extension.
    attr_accessor :cnbase

    # The extension.
    attr_accessor :ext

    # Extracted meta information for the path.
    attr_accessor :meta_info

    # Create a new Path object for +path+. The optional block needs to return an IO object for the
    # content of the path.
    def initialize(path, &ioblock)
      @meta_info = {}
      @io = SourceIO.new(&ioblock) if block_given?
      analyse(path)
    end

    # Mount this path at the mount point +mp+ and return the new path object.
    def mount_at(mp)
      temp = dup
      temp.path = File.join(mp, @path)
      if @path == '/'
        temp.send(:analyse, temp.path)
      else
        temp.directory = File.join(File.dirname(temp.path), '/')
      end
      temp
    end

    # Has the content of this path changed since the last webgen run? This default implementation
    # always returns +true+, a specialized sub class needs to override this behaviour!
    def changed?
      true
    end

    # Duplicate the path object.
    def dup
      temp = super
      temp.meta_info = @meta_info.dup
      temp
    end

    # The IO object associated with the path.
    def io
      if @io
        @io
      else
        raise "No IO object defined for the path #{self}"
      end
    end

    # The canonical name created from the filename (created from cnbase and extension).
    def cn
      @cnbase + (@ext.length > 0 ? '.' + @ext : '')
    end

    # Utility method for creating the lcn from +cn+ and the language +lang+.
    def self.lcn(cn, lang)
      if lang.nil?
        cn
      else
        cn.split('.').insert(1, lang.to_s).join('.')
      end
    end

    # The localized canonical name created from the filename.
    def lcn
      self.class.lcn(cn, @meta_info['lang'])
    end

    # Compare this object to another Path or a String.
    def ==(other)
      if other.kind_of?(Path)
        other.path == @path
      elsif other.kind_of?(String)
        other == @path
      else
        false
      end
    end
    alias_method(:eql?, :==)

    # Return +true+ if the localized path matches the given +pattern+. For information on which
    # patterns are supported, have a look at the documentation of File.fnmatch.
    def =~(pattern)
      File.fnmatch(pattern, File.join(@directory, lcn), File::FNM_DOTMATCH|File::FNM_CASEFOLD|File::FNM_PATHNAME)
    end

    # Implemented sothat a Path looks like a String when used as key in a hash.
    def <=>(other)
      @path <=> other.to_str
    end

    # Implemented sothat a Path looks like a String when used as key in a hash.
    def hash
      @path.hash
    end

    def to_s #:nodoc:
      @path.dup
    end
    alias_method :to_str, :to_s

    def inspect #:nodoc:
      "#<Path: #{@path}>"
    end

    #######
    private
    #######

    FILENAME_RE = /^(?:(\d+)\.)?([^.]*?)(?:\.(\w\w\w?)(?=.))?(?:\.(.*))?$/

    # Analyse the +path+ and fill the object with the extracted information.
    def analyse(path)
      @path = path
      @basename = File.basename(path)
      @directory = File.join(File.dirname(path), '/')
      matchData = FILENAME_RE.match(@basename)

      @meta_info['sort_info'] = matchData[1].to_i
      @cnbase                 = matchData[2]
      @meta_info['lang']      = Webgen::LanguageManager.language_for_code(matchData[3])
      @ext                    = (@meta_info['lang'].nil? && !matchData[3].nil? ? matchData[3].to_s + '.' : '') + matchData[4].to_s

      @meta_info['title']     = @cnbase.tr('_-', ' ').capitalize
    end

  end

end
