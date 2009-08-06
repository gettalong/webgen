# -*- encoding: utf-8 -*-

require 'pathname'
require 'webgen/languages'

module Webgen

  # == General Information
  #
  # A Path object provides information about a path that is used to create one or more nodes as well
  # as methods for accessing the path's content. So a Path object always refers to a source path. In
  # contrast, output paths are always strings and just specify the location where a specific node
  # should be written to.
  #
  # Note the +path+ and +source_path+ attributes of a Path object:
  #
  # * The +source_path+ specifies a path string that was directly created by a Source object. Each
  #   Path object must have such a valid source path sothat webgen can infer the Path the lead to
  #   the creation of a Node object later.
  #
  # * In contrast, the +path+ attribute specifies the path that is used to create the canonical name
  #   (and by default the output path) of a Node object. Normally it is the same as the
  #   +source_path+ but can differ (e.g. when fragment nodes are created for page file nodes).
  #
  # A Path object can represent one of three different things: a directory, a file or a fragment. If
  # the +path+ ends with a slash character, then the path object represents a directory, if the path
  # contains a hash character anywhere, then the path object represents a fragment and else it
  # represents a file. Have a look at the webgen manual to see the exact format of a path!
  #
  # == Relation to Source classes
  #
  # A webgen source class needs to derive a specialized path class from this class and implement an
  # approriate #changed? method that returns +true+ if the path's content has changed since the last
  # webgen run.
  class Path

    # Helper class for easy access to the content of a path.
    #
    # This class is used sothat the creation of the real IO object for #stream can be delayed till
    # it is actually needed. This is done by not directly requiring the user of this class to supply
    # the IO object, but by requiring a block that creates the real IO object.
    class SourceIO

      # Create a new SourceIO object. A block has to be specified that returns the to-be-wrapped IO
      # object.
      def initialize(&block)
        @block = block
        raise ArgumentError, 'You need to provide a block which returns an IO object' if @block.nil?
      end

      # Provide direct access to the wrapped IO object by yielding it. After the method block
      # returns the IO object is automatically closed.
      #
      # The parameter +mode+ specifies the mode in which the wrapped IO object should be opened.
      # This can be used, for example, to open a file in binary mode (or specify a certain input
      # encoding under Ruby 1.9).
      def stream(mode = 'r')
        io = @block.call(mode)
        yield(io)
      ensure
        io.close
      end

      # Return the whole content of the wrapped IO object as string. For a description of the
      # parameter +mode+ see #stream.
      def data(mode = 'r')
        stream(mode) {|io| io.read}
      end

    end


    # Make the given +path+ absolute by prepending the absolute directory path +base+ if necessary.
    # Also resolves all '..' and '.' references in +path+.
    def self.make_absolute(base, path)
      raise(ArgumentError, 'base has to be an absolute path, ie. needs to start with a slash') unless base =~ /\//
      Pathname.new(path =~ /^\// ? path : File.join(base, path)).cleanpath.to_s
    end

    # Return +true+ if the given +path+ matches the given +pattern+. For information on which
    # patterns are supported, have a look at the documentation of File.fnmatch.
    def self.match(path, pattern)
      pattern += '/' if path =~ /\/$/ && pattern !~ /\/$|^$/
      File.fnmatch(pattern, path.to_s, File::FNM_DOTMATCH|File::FNM_CASEFOLD|File::FNM_PATHNAME)
    end


    include Comparable

    # The full path for which this Path object was created.
    attr_reader :path

    # A string specifying the path that lead to the creation of this path.
    attr_reader :source_path

    # The string specifying the parent path
    attr_reader :parent_path

    # The canonical name of the path without the extension.
    attr_accessor :basename

    # The extension of the +path+.
    attr_accessor :ext

    # Extracted meta information for the path.
    attr_accessor :meta_info

    # Specifies whether this path should be used during the "tree update" phase of a webgen run or
    # only later during node resolution.
    attr_writer :passive

    # Is this path only used later during node resolution? Defaults to +false+, i.e. used during the
    # "tree update" phase.
    def passive?; @passive; end


    # Create a new Path object for +path+. The optional +source_path+ parameter specifies the path
    # string that lead to the creation of this path. The optional block needs to return an IO object
    # for getting the content of the path.
    #
    # The +path+ needs to be in a well defined format which can be looked up in the webgen manual.
    def initialize(path, source_path = path, &ioblock)
      @meta_info = {}
      @io = block_given? ? SourceIO.new(&ioblock) : nil
      @source_path = source_path
      @passive = false
      analyse(path)
    end

    # Mount this path at the mount point +mp+, optionally stripping +prefix+ from the parent path,
    # and return the new path object.
    #
    # The parameters +mp+ and +prefix+ have to be absolute directory paths, ie. they have to start
    # and end with a slash and must not contain any hash characters!
    #
    #--
    # Can't use self.class.new(...) here because the semantics of the sub constructors is not know
    #++
    def mount_at(mp, prefix = nil)
      raise(ArgumentError, "The mount point (#{mp}) must be a valid directory path") if mp =~ /^[^\/]|#|[^\/]$/
      raise(ArgumentError, "The strip prefix (#{prefix}) must be a valid directory path") if !prefix.nil? && prefix =~ /^[^\/]|#|[^\/]$/

      temp = dup
      strip_re = /^#{Regexp.escape(prefix.to_s)}/
      temp.instance_variable_set(:@path, temp.path.sub(strip_re, ''))
      reanalyse = (@path == '/' || temp.path == '')
      temp.instance_variable_set(:@path, File.join(mp, temp.path))
      temp.instance_variable_set(:@source_path, temp.path) if @path == @source_path
      if reanalyse
        temp.send(:analyse, temp.path)
      else
        temp.instance_variable_set(:@parent_path, File.join(mp, temp.parent_path.sub(strip_re, '')))
      end
      temp
    end

    # Duplicate the path object.
    def dup
      temp = super
      temp.instance_variable_set(:@meta_info, @meta_info.dup)
      temp
    end

    # Has the content of this path changed since the last webgen run? This default implementation
    # always returns +true+, a specialized sub class needs to override this behaviour!
    def changed?
      true
    end

    # The SourceIO object associated with the path.
    def io
      if @io
        @io
      else
        raise "No IO object defined for the path #{self}"
      end
    end

    # The canonical name created from the +path+ (namely from the parts +basename+ and +extension+).
    def cn
      @basename + (@ext.length > 0 ? '.' + @ext : '') + (@basename != '/' && @path =~ /.\/$/ ? '/' : '')
    end

    # Utility method for creating the lcn from the +cn+ and the language +lang+.
    def self.lcn(cn, lang)
      if lang.nil?
        cn
      else
        cn.split('.').insert((cn =~ /^\./ ? 2 : 1), lang.to_s).join('.')
      end
    end

    # The localized canonical name created from the +path+.
    def lcn
      self.class.lcn(cn, @meta_info['lang'])
    end

    # The absolute canonical name of this path.
    def acn
      if @path =~ /#/
        self.class.new(@parent_path).acn + cn
      else
        @parent_path + cn
      end
    end

    # The absolute localized canonical name of this path.
    def alcn
      if @path =~ /#/
        self.class.new(@parent_path).alcn + lcn
      else
        @parent_path + lcn
      end
    end

    # Equality -- Return +true+ if +other+ is a Path object with the same #path or if +other+ is a
    # String equal to the #path. Else return +false+.
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

    # Compare the #path of this object to <tt>other.path</tt>
    def <=>(other)
      @path <=> other.path
    end

    def hash #:nodoc:
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

    # Analyse the +path+ and fill the object with the extracted information.
    def analyse(path)
      @path = path
      if @path =~ /#/
        analyse_fragment
      elsif @path =~ /\/$/
        analyse_directory
      else
        analyse_file
      end
      @meta_info['title'] = @basename.tr('_-', ' ').capitalize
      @ext ||= ''
      raise "The basename of a path may not be empty: #{@path}" if @basename.empty? || @basename == '#'
      raise "The parent path must start with a slash: #{@path}" if @path !~ /^\// && @path != '/'
    end

    # Analyse the path assuming it is a directory.
    def analyse_directory
      @parent_path = (@path == '/' ? '' : File.join(File.dirname(@path), '/'))
      @basename = File.basename(@path)
    end

    FILENAME_RE = /^(?:(\d+)\.)?(\.?[^.]*?)(?:\.(\w\w\w?)(?=\.))?(?:\.(.*))?$/

    # Analyse the path assuming it is a file.
    def analyse_file
      @parent_path = File.join(File.dirname(@path), '/')
      match_data = FILENAME_RE.match(File.basename(@path))

      @meta_info['sort_info'] = (match_data[1].nil? ? nil : match_data[1].to_i)
      @basename               = match_data[2]
      @meta_info['lang']      = Webgen::LanguageManager.language_for_code(match_data[3])
      @ext                    = (@meta_info['lang'].nil? && !match_data[3].nil? ? match_data[3].to_s : '') + match_data[4].to_s
    end

    # Analyse the path assuming it is a fragment.
    def analyse_fragment
      @parent_path, @basename =  @path.scan(/^(.*?)(#.*?)$/).first
      raise "The parent path of a fragment path must be a file path and not a directory path: #{@path}" if @parent_path =~ /\/$/
      raise "A fragment path must only contain one hash character: #{path}" if @path.count("#") > 1
    end

  end

end
