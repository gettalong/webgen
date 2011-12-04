# -*- encoding: utf-8 -*-

require 'uri'
require 'webgen/languages'

module Webgen

  # == About
  #
  # A Path object provides information about a path that is used to create one or more nodes as well
  # as methods for accessing/modifying the path's content. So a Path object always refers to a path
  # from which nodes are created! In contrast, destination paths are just strings and specify the
  # location where a specific node should be written to.
  #
  # Note the +path+ and +source_path+ attributes of a Path object:
  #
  # * The +source_path+ specifies a path string that was directly created by a Source object. Each
  #   Path object must have such a valid source path so that webgen can infer the Path the lead to
  #   the creation of a Node object later.
  #
  # * In contrast, the +path+ attribute specifies the path that is used to create the canonical name
  #   (and by default the destination path) of a Node object. Normally it is the same as the
  #   +source_path+ but can differ (e.g. when fragment nodes are created for page file nodes).
  #
  # A Path object can represent one of three different things: a directory, a file or a fragment. If
  # the +path+ ends with a slash character, then the path object represents a directory, if the path
  # contains a hash character anywhere, then the path object represents a fragment and else it
  # represents a file. Have a look at the webgen manual to see the exact format that can be used for
  # a path string!
  #
  class Path

    # This pattern is the the same as URI::UNSAFE except that the hash character (#) is also
    # not escaped. This is needed so that paths with fragments work correctly.
    URL_UNSAFE_PATTERN = Regexp.new("[^#{URI::PATTERN::UNRESERVED}#{URI::PATTERN::RESERVED}#]") # :nodoc:

    # Construct an internal URL for the given +path+ which can be an acn/alcn/absolute path. If the
    # parameter +make_absolute+ is +true+, then a relative URL will be made absolute by prepending
    # the special URL <tt>webgen:://webgen.localhost/</tt>.
    def self.url(path, make_absolute = true)
      url = URI.parse(URI::DEFAULT_PARSER.escape(path, URL_UNSAFE_PATTERN))
      url = URI.parse('webgen://webgen.localhost/') + url unless url.absolute? || !make_absolute
      url
    end

    # Append the +path+ to the +base+ path. The +base+ parameter has to be an acn/alcn/absolute
    # path. If it represents a directory, it needs to have a trailing slash! The +path+ parameter
    # doesn't need to be absolute and may contain path patterns.
    def self.append(base, path)
      raise(ArgumentError, 'base needs to start with a slash (i.e. be an absolute path)') unless base =~ /^\//
      url = url(base) + url(path, false)
      url.path + (url.fragment.nil? ? '' : '#' + url.fragment)
    end

    # Return +true+ if the given path string matches the given path pattern. For information on
    # which patterns are supported, have a look at the API documentation of File.fnmatch.
    def self.matches_pattern?(path, pattern, options = File::FNM_DOTMATCH|File::FNM_CASEFOLD|File::FNM_PATHNAME)
      pattern += '/' if path.to_s =~ /\/$/ && pattern !~ /\/$|^$/
      File.fnmatch(pattern, path, options)
    end

    # Construct a localized canonical name from a given canonical name and a language.
    def self.lcn(cn, lang)
      if lang.nil?
        cn
      else
        cn.split('.').insert((cn =~ /^\./ ? 2 : 1), lang.to_s).join('.')
      end
    end


    include Comparable

    # Create a new Path object for +path+.
    #
    # The +source_path+ information can be provided by setting the meta information key :+src+ if
    # +source_path+ is different from +path+. The optional block needs to return an IO object for
    # getting the content of the path (see #io and #data).
    #
    # The +path+ needs to be in a well defined format which can be looked up in the webgen manual.
    def initialize(path, meta_info = {}, &ioblock)
      @path = path.freeze
      @meta_info = meta_info
      @ioblock = block_given? ? ioblock : nil
      @source_path = @meta_info.delete(:src)
    end

    def initialize_copy(orig) #:nodoc:
      super
      @meta_info = orig.instance_variable_get(:@meta_info).dup
    end

    # The original path string from which this Path object was created.
    attr_reader :path

    # A string specifying the path that lead to the creation of this path.
    def source_path
      @source_path || path
    end

    # Meta information about the path.
    def meta_info
      defined?(@basename) ? @meta_info : (analyse; @meta_info)
    end

    # Set the meta information +key+ to +value+.
    #
    # This method has to be used to set meta information without triggering analysation of the path
    # string!
    def []=(key, value)
      @meta_info[key] = value
    end

    # The string specifying the parent path
    def parent_path
      defined?(@parent_path) ? @parent_path : (analyse; @parent_path)
    end

    # The canonical name of the path without the extension.
    def basename
      defined?(@basename) ? @basename : (analyse; @basename)
    end

    # The extension of the path.
    def ext
      defined?(@ext) ? @ext : (analyse; @ext)
    end

    # Set the extension of the path.
    def ext=(value)
      defined?(@ext) || analyse
      @ext = value
    end

    # The canonical name created from the +path+ (namely from the parts +basename+ and +extension+).
    def cn
      basename + (ext.length > 0 ? '.' + ext : '') + (basename != '/' && @path =~ /.\/$/ ? '/' : '')
    end

    # The localized canonical name created from the +path+.
    def lcn
      self.class.lcn(cn, meta_info['lang'])
    end

    # The absolute canonical name of this path.
    def acn
      if @path =~ /#/
        self.class.new(parent_path).acn + cn
      else
        parent_path + cn
      end
    end

    # The absolute localized canonical name of this path.
    def alcn
      if @path =~ /#/
        self.class.new(parent_path).alcn + lcn
      else
        parent_path + lcn
      end
    end


    # Mount this path at the mount point +mp+, optionally stripping +prefix+ from the parent path,
    # and return the new Path object.
    #
    # The parameters +mp+ and +prefix+ have to be absolute directory paths, ie. they have to start
    # and end with a slash and must not contain any hash characters!
    #
    # Also note that mounting a path is not possible once it is fully initialized, i.e. once some
    # information extracted from the path string is accessed.
    def mount_at(mp, prefix = nil)
      raise(ArgumentError, "Can't mount a fully initialized path") if defined?(@basename)
      raise(ArgumentError, "The mount point (#{mp}) must be a valid directory path") if mp =~ /^[^\/]|#|[^\/]$/
      raise(ArgumentError, "The strip prefix (#{prefix}) must be a valid directory path") if !prefix.nil? && prefix =~ /^[^\/]|#|[^\/]$/

      temp = self.class.new(File.join(mp, @path.sub(/^#{Regexp.escape(prefix.to_s)}/, '')),
                            @meta_info.merge(:src => @source_path))
      temp
    end

    # Provide access to the IO object of the path by yielding it. After the method block returns,
    # the IO object is automatically closed. An error is raised, if no IO object is associated with
    # the Path instance.
    #
    # The parameter +mode+ specifies the mode in which the IO object should be opened. This can be
    # used, for example, to open a file in binary mode (or specify a certain input encoding under
    # Ruby 1.9).
    def io(mode = 'r') # :yields: io
      raise "No IO object defined for the path #{self}" if @ioblock.nil?
      io = @ioblock.call(mode)
      yield(io)
    ensure
      io.close if io
    end

    # Return the content of the IO object of the path as string. For a description of the
    # parameter +mode+ see #stream.
    #
    # An error is raised, if no IO object is associated with the Path instance.
    def data(mode = 'r')
      io(mode) {|io| io.read}
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
      @path <=> other.to_str
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

    # Analyse the path and extract the needed information.
    def analyse
      if @path =~ /#/
        analyse_fragment
      elsif @path =~ /\/$/
        analyse_directory
      else
        analyse_file
      end
      @meta_info['title'] ||= @basename.tr('_-', ' ').capitalize
      @ext ||= ''
      raise "The basename of a path may not be empty: #{@path}" if @basename.empty? || @basename == '#'
      raise "The parent path must start with a slash: #{@path}" if @path !~ /^\//
    end

    # Analyse the path assuming it is a directory.
    def analyse_directory
      @parent_path = (@path == '/' ? '' : File.join(File.dirname(@path), '/'))
      @basename = File.basename(@path)
    end

    FILENAME_RE = /^(?:(\d+)\.)?(\.?[^.]*?)(?:\.(\w\w\w?)(?=\.))?(?:\.(.*))?$/ #:nodoc:

    # Analyse the path assuming it is a file.
    def analyse_file
      @parent_path = File.join(File.dirname(@path), '/')
      match_data = FILENAME_RE.match(File.basename(@path))

      if !match_data[1].nil? && match_data[3].nil? && match_data[4].nil? # handle special case of sort_info.basename as basename.ext
        @basename = match_data[1]
        @ext = match_data[2]
      else
        @meta_info['sort_info'] ||= (match_data[1].nil? ? nil : match_data[1].to_i)
        @basename               = match_data[2]
        @meta_info['lang']      ||= Webgen::LanguageManager.language_for_code(match_data[3])
        @ext                    = (@meta_info['lang'].nil? && !match_data[3].nil? ? match_data[3].to_s + '.' : '') + match_data[4].to_s
      end
    end

    # Analyse the path assuming it is a fragment.
    def analyse_fragment
      @parent_path, @basename =  @path.scan(/^(.*?)(#.*?)$/).first
      raise "The parent path of a fragment path must be a file path and not a directory path: #{@path}" if @parent_path =~ /\/$/
      raise "A fragment path must only contain one hash character: #{path}" if @path.count("#") > 1
    end

  end

end
