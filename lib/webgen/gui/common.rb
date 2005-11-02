require 'csv'
require 'webgen'

module Webgen

  class Website

    attr_reader :directory

    def initialize( directory )
      @directory = directory
    end

    def files
    end

    def self.languages
      unless defined?( @@languages )
        @@languages = []
        code_file = File.join( CorePlugins::Configuration.data_dir, 'data/ISO-639-2_values_8bits.txt' )
        CSV::Reader.parse( File.open( code_file, 'r' ), ?| ) do |row|
          @@languages << [row[0].data, row[3].data] unless !@@languages.last.nil? && @@languages.last[0] == row[0].data && @@languages.last[1] == row[3].data
        end
      end
      @@languages
    end

    def self.templates
      Dir[File.join( CorePlugins::Configuration.data_dir, 'website_templates', '*' )].collect {|f| File.basename( f )}
    end

    def self.styles
      Dir[File.join( CorePlugins::Configuration.data_dir, 'website_styles', '*' )].collect {|f| File.basename( f )}
    end

  end

end
