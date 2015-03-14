# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for showing extension bundles.
    class ShowBundlesCommand < CmdParse::Command

      def initialize # :nodoc:
        super('bundles', takes_commands: false)
        short_desc('Show extension bundles')
        long_desc(<<DESC)
Shows all loaded, available and installable bundles.

Loaded bundles are already used by the website, available ones are installed but
not used and installable bundles can be installed if needed.

Hint: The global verbosity option enables additional output.
DESC
        options.on("-r", "--[no-]remote", "Use remote server for listing installable bundles") do |remote|
          @remote = remote
        end
        @remote = false
      end

      def execute # :nodoc:
        bundles = command_parser.website.ext.bundle_infos.bundles.dup
        bundles.each {|n,d| d[:state] = :loaded}

        populate_hash = lambda do |file|
          bundle_name = File.basename(File.dirname(file))
          info_file = File.join(File.dirname(file), 'info.yaml')
          bundles[bundle_name] ||= (File.file?(info_file) ? YAML.load(File.read(info_file)) : {})
          bundles[bundle_name][:state] ||= :available
          bundles[bundle_name]
        end

        $LOAD_PATH.each do |path|
          Dir.glob(File.join(path, 'webgen/bundle', '*', 'init.rb')).each do |file|
            populate_hash.call(file)
          end
        end

        Gem::Specification.map do |spec|
          [spec.name, spec.matches_for_glob("webgen/bundle/*/init.rb")]
        end.select do |name, files|
          !files.empty?
        end.each do |name, files|
          files.each do |file|
            hash = populate_hash.call(file)
            hash[:gem] = name
          end
        end

        if @remote
          Gem::SpecFetcher.fetcher.detect(:latest) do |name_tuple|
            next unless name_tuple.name =~ /webgen-(.*)-bundle/
            bundle_name = $1
            if !bundles.has_key?(bundle_name)
              bundles[bundle_name] = {:state => :installable, :gem => name_tuple.name}
            end
          end
        end

        bundles.sort do |a, b|
          if a.last[:state] == b.last[:state]
            a.first <=> b.first
          elsif a.last[:state] == :loaded
            -1
          elsif b.last[:state] == :loaded
            1
          elsif a.last[:state] == :available
            -1
          else
            1
          end
        end.each do |name, data|
          format_bundle_info(name, data)
        end
      end

      def format_bundle_info(name, data)
        puts(Utils.light(Utils.blue(name)))
        puts("  State:    #{data[:state]}")
        puts("  Rubygem:  #{data[:gem]}") if data[:gem]
        if command_parser.verbose && data['author']
          puts("  Author:   #{data['author']}")
          print("  Summary:  ")
          puts(Utils.format(data['summary'], 78, 12, false))
          puts("  Version:  #{data['version']}") if data['version']
        end
        puts
      end
      private :format_bundle_info

    end

  end
end
