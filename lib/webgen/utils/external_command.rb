# -*- encoding: utf-8 -*-

require 'webgen/error'
require 'systemu'

module Webgen
  module Utils

    # This module provides methods for easily working with external commands.
    module ExternalCommand

      # Raise an error if the given command is not available.
      #
      # This just checks if the exit status is zero.
      def self.ensure_available!(cmd, *args)
        status = systemu([cmd, *args], 'stdout' => '')
        raise Webgen::CommandNotFoundError.new(cmd) if status.exitstatus != 0
      end

    end

  end
end




