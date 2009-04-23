module Webgen

  class Node

    def flagged(key)
      warn("Deprecation warning: this method will be removed in one of the next releases - use Node#flagged? instead!")
      flagged?(key)
    end

  end

end
