module Webgen

  class Node

    def flagged(key)
      warn("Deprecation warning (~ #{caller.first}): this method will be removed in one of the next releases - use Node#flagged? instead!")
      flagged?(key)
    end

    def absolute_cn
      warn("Deprecation warning (~ #{caller.first}): this method will be removed in one of the next releases - use Node#acn instead!")
      acn
    end

    def absolute_lcn
      warn("Deprecation warning (~ #{caller.first}): this method will be removed in one of the next releases - use Node#alcn instead!")
      alcn
    end

  end

  class Path

    def cnbase
      warn("Deprecation warning (~ #{caller.first}): this method will be removed in one of the next releases - use Path#basename instead!")
      @basename
    end

    def cnbase=(value)
      warn("Deprecation warning (~ #{caller.first}): this method will be removed in one of the next releases - use Path#basename= instead!")
      basename = value
    end

  end

  def self.const_missing(const)
    if const.to_s == 'Block'
      warn("Deprecation warning (~ #{caller.first}): Webgen::Block name will be removed in one of the next releases - use Webgen::Page::Block instead!")
      Webgen::Page::Block
    elsif const.to_s == "WebgenPageFormatError"
      warn("Deprecation warning (~ #{caller.first}): Webgen::WebgenPageFormatError name will be removed in one of the next releases - use Webgen::Page::FormatError instead!")
      Webgen::Page::FormatError
    else
      super
    end
  end

  module ContentProcessor

    def self.const_missing(const)
      if const.to_s == 'Context'
        warn("Deprecation warning (~ #{caller.first}): Webgen::ContentProcessor::Context is now named Webgen::Context! This alias will be removed in one of the next releases.")
        Webgen::Context
      else
        super
      end
    end

    module Deprecated

      def deprecate(old, new, obj)
        klass = Class.new
        klass.instance_methods.select {|m| m.to_s !~ /^(__|instance_eval|object_id)/}.each {|m| klass.__send__(:undef_method, m)}
        result = klass.new
        result.instance_eval { @old, @new, @obj = old, new, obj }
        def result.inspect; end
        def result.method_missing(sym, *args, &block)
          Kernel::warn("Deprecation warning (~ #{caller.first}): The alias '#{@old}' will be removed in one of the next releases - use '#{@new}' instead!")
          @obj.send(sym, *args, &block)
        end
        result
      end

    end

  end

  module Common

    def self.absolute_path(path, base)
      warn("Deprecation warning (~ #{caller.first}): this method will be removed in one of the next releases - use Webgen::Path.make_absolute(base, path) instead!")
      Path.make_absolute(base, path)
    end

  end

end
