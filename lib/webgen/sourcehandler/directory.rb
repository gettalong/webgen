module Webgen::SourceHandler

  # Handles directory source paths.
  class Directory

    include Base

    # Return an empty string to signal that the directory should be written to the output.
    def content(node)
      ''
    end

  end

end
