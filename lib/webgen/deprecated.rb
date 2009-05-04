module Webgen

  class Node

    def flagged(key)
      warn("Deprecation warning: this method will be removed in one of the next releases - use Node#flagged? instead!")
      flagged?(key)
    end

  end

  def self.const_missing(const)
    if const.to_s == 'Block'
      warn("Deprecation warning: Webgen::Block name will be removed in one of the next releases - use Webgen::Page::Block instead!")
      Webgen::Page::Block
    elsif const.to_s == "WebgenPageFormatError"
      warn("Deprecation warning: Webgen::WebgenPageFormatError name will be removed in one of the next releases - use Webgen::Page::FormatError instead!")
      Webgen::Page::FormatError
    else
      super
    end
  end

  module ContentProcessor

    def self.const_missing(const)
      if const.to_s == 'Context'
        warn("Deprecation warning: Webgen::ContentProcessor::Context is now named Webgen::Context! This alias will be removed in one of the next releases.")
        Webgen::Context
      else
        super
      end
    end

    module Deprecated

      def deprecate(old, new, obj)
        klass = Class.new
        klass.instance_methods.select {|m| m.to_s !~ /^(__|instance_eval)/}.each {|m| klass.__send__(:undef_method, m)}
        result = klass.new
        result.instance_eval { @old, @new, @obj = old, new, obj }
        def result.method_missing(sym, *args, &block)
          Kernel::warn("Deprecation warning (~ #{caller.first}): The alias '#{@old}' will be removed in one of the next releases - use '#{@new}' instead!")
          @obj.send(sym, *args, &block)
        end
        result
      end

    end

  end

end
