require 'webgen/languages'

module Webgen

  class Path

    include Comparable

    # The source path
    attr_accessor :path

    # The basename part of the path.
    attr_accessor :basename

    # The directory part of the path.
    attr_accessor :directory

    # The cn without the extension.
    attr_accessor :cnbase

    # The extension.
    attr_accessor :ext

    # Extracted meta information for the path.
    attr_accessor :meta_info

    def initialize(path, &ioblock)
      @meta_info = {}
      @ioblock = ioblock if block_given?
      analyse(path)
    end

    def mount_at(mp)
      temp = dup
      temp.path = File.join(mp, @path)
      temp.directory = File.join(File.dirname(temp.path), '/')
      temp
    end

    def dup
      temp = super
      temp.meta_info = @meta_info.dup
      temp
    end

    def io(&block)
      if @ioblock
        @ioblock.call(block)
      else
         raise "No IO object defined for the path #{self}"
      end
    end

    # The canonical name created from the filename (created from cnbase and extension).
    def cn
      @cnbase + (@ext.length > 0 ? '.' + @ext : '')
    end

    # Utility method for creating the lcn from cn and the language.
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

    def =~(pattern)
      File.fnmatch(pattern, File.join(@directory, lcn), File::FNM_DOTMATCH|File::FNM_CASEFOLD|File::FNM_PATHNAME)
    end

    def <=>(other)
      @path <=> other.to_str
    end

    def hash
      @path.hash
    end

    def to_s
      @path.dup
    end
    alias_method :to_str, :to_s

    def inspect
      "#<Path: #{@path}>"
    end

    #######
    private
    #######

    FILENAME_RE = /^(?:(\d+)\.)?([^.]*?)(?:\.(\w\w\w?)(?=.))?(?:\.(.*))?$/

    # Analyses the +filename+ and fills the object with the extracted information.
    def analyse(path)
      @path = path
      @basename = File.basename(path)
      @directory = File.join(File.dirname(path), '/')
      matchData = FILENAME_RE.match(@basename)

      @meta_info['orderInfo'] = matchData[1].to_i
      @cnbase                 = matchData[2]
      @meta_info['lang']      = Webgen::LanguageManager.language_for_code(matchData[3])
      @ext                    = (@meta_info['lang'].nil? && !matchData[3].nil? ? matchData[3].to_s + '.' : '') + matchData[4].to_s

      @meta_info['title']     = @cnbase.tr('_-', ' ').capitalize
    end

  end

end
