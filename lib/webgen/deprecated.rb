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

end
