# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for listing extension bundles.
    class ListBundleCommand < CmdParse::Command

      def initialize # :nodoc:
        super('list', false, false, true)
        self.short_desc = 'List extension bundles'
        self.description = Utils.format_command_desc(<<DESC)
Lists all loaded, installed and available extension bundles.

Loaded bundles are already used by the website, installed ones are installed but
not used and available bundles can be installed if needed.
DESC
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Options:"
          opts.on("-r", "--[no-]remote",
                  *Utils.format_option_desc("Use remote server for listing available bundles")) do |remote|
            @remote = remote
          end
          opts.on("-v", "--[no-]verbose",
                  *Utils.format_option_desc("Verbose output")) do |v|
            @verbose = v
          end
        end
        @verbose = false
        @remote = false
      end

      def execute(args)
        bundles = {}
        commandparser.website.ext.bundles.each do |bundle, info_file|
          bundles.update(bundle => (info_file ? YAML.load(File.read(info_file)) : {}))
        end
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
          dep = Gem::Deprecate.skip_during { Gem::Dependency.new(/webgen-.*-bundle/, Gem::Requirement.default) }
          Gem::SpecFetcher.fetcher.find_matching(dep).each do |spec, uri|
            bundle_name = spec.first.sub(/webgen-(.*)-bundle/, '\1')
            if !bundles.has_key?(bundle_name)
              bundles[bundle_name] = {:state => :installable, :gem => spec.first}
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
        if @verbose && data['author']
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
