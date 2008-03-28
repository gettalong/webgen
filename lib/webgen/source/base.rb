module Webgen::Source

  class Base

    include Enumerable

    def each(&block)
      paths.each(&block)
    end

  end

end
