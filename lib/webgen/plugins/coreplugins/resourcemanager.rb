#
#--
#
# $Id$
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'fileutils'
require 'webgen/plugins/tags/tag_processor'
require 'webgen/plugins/filehandlers/filehandler'

module CorePlugins

  class ResourceManager < Webgen::Plugin

    class Resource

      attr_reader :name
      attr_reader :output_path
      attr_accessor :predefined
      attr_accessor :type

      def initialize( name, type, output_path )
        @name = name
        @type = type
        @output_path = output_path.sub( /^\//, '' )
        @used = false
      end

      # Returns the relative path from the node to the resource.
      def route_from( node )
        node.route_to( '/' + @output_path )
      end

      # Returns the complete destination path.
      def dest_path( root_dir )
        File.join( root_dir, @output_path )
      end

      # Mark the resource as referenced. Only referenced resources are written to the output directory.
      def referenced!
        @referenced = true
      end

      # Has the resource been used somewhere?
      def referenced?
        @referenced
      end

      # Can the resource be written to the output directory?
      def write_resource?( root_dir )
        @referenced
      end

      # Write the resource to the output directory.
      def write_resource( root_dir )
        raise NotImplementedError
      end

    end

    class FileResource < Resource

      attr_reader :res_path

      def initialize( name, output_path, res_path )
        super( name, :file, output_path )
        @res_path = res_path
      end

      def data
        File.read( @res_path )
      end

      def write_resource?( root_dir )
        referenced? && Webgen::Plugin['FileHandler'].file_modified?( @res_path, dest_path( root_dir ) )
      end

      def write_resource( root_dir )
        FileUtils.cp( res_path, dest_path( root_dir ) ) if write_resource?( root_dir )
      end

    end

    class MemoryResource < Resource

      def initialize( name, output_path )
        super( name, :memory, output_path )
        @data = ''
      end

      def data
        @data
      end

      def append_data( data )
        @data << data
      end

      def write_resource( root_dir )
        File.open( dest_path, 'w' ) {|file| file.write( data )} if write_resource?( root_dir )
      end

    end


    infos(
          :summary => "Provides access to pre- and userdefined resources",
          :description => "The resource manager manages a list of predefined and " +
          "userdefined resources. These resources can be used, for example, in page files."
          )
    param 'resources', [], 'User defined file resources. Value has to be an array of ' +
      'arrays with three strings defining name, resource path and output path'

    depends_on 'FileHandlers::FileHandler'


    def initialize( plugin_manager )
      super
      @plugin_manager['FileHandlers::FileHandler'].add_msg_listener( :AFTER_ALL_WRITTEN, method( :write_resources ) )
      @resources = {}
      define_webgen_resources unless Webgen.data_dir.empty?
      define_user_resources
    end


    # Adds an exisiting file resource which can be referenced later by using +name+. The +output_path+
    # should be an absolute path, like +/images/logo.png+. If not, it will be relative to the output
    # directory.
    def define_file_resource( name, resource_path, output_path )
      if File.exists?( resource_path )
        define_resource( name, FileResource.new( name, output_path, resource_path ) )
      end
    end

    # Adds a new resource which can be referenced later by using +name+. The +output_path+
    # should be an absolute path, like +/images/logo.png+. If not, it will be relative to the output
    # directory.
    def define_memory_resource( name, output_path )
      define_resource( name, MemoryResource.new( name, output_path ) )
    end

    def define_resource( name, res )
      @resources[name] = res unless @resources.has_key?( name )
    end

    # Returns the requested resource.
    def get_resource( name )
      @resources[name]
    end

    # Appends given +data+ to the resource +name+. Data can only be appended to memory resources!
    def append_data( name, data )
      if (res = get_resource( name )) && res.type == :memory
        res.append_data( data )
      else
        log(:error) {"Resource #{name} does not exist or data cannot be appended to it!" }
      end
    end

    #######
    private
    #######

    def define_webgen_resources
      define_file_resource( 'webgen-logo', File.join( Webgen.data_dir, 'resources', 'images', 'webgen_logo.png' ),
                            '/images/webgen-logo.png'
                            ).predefined = "The logo of webgen as seen on the homepage."
      define_file_resource( 'webgen-generated', File.join( Webgen.data_dir, 'resources', 'images', 'generated_by_webgen.png' ),
                            '/images/webgen-generated-by.png'
                            ).predefined = "A 88x31 image for use on web sites that were generated by webgen."
      define_file_resource( 'w3c-valid-css', File.join( Webgen.data_dir, 'resources', 'images', 'valid-css.gif' ),
                            '/images/w3c-valid-css.gif'
                            ).predefined = 'The W3C image for valid css.'
      define_file_resource( 'w3c-valid-xhtml11', File.join( Webgen.data_dir, 'resources', 'images', 'valid-xhtml11.png' ),
                            '/images/w3c-valid-xhtml11.png'
                            ).predefined = "The W3C image for valid XHTML1.1"

      define_webgen_emoticons
      define_webgen_icons

      define_memory_resource( 'webgen-css', '/css/webgen.css'
                              ).predefined = "Plugins use this resource for their CSS styles."
      define_memory_resource( 'webgen-javascript', '/css/webgen.js'
                              ).predefined = "Plugins use this resource for their Javascript fragments."
    end

    def define_webgen_emoticons
      Dir[File.join( Webgen.data_dir, 'resources', 'emoticons', '*/')].each do |pack_dir|
        pack = File.basename( pack_dir )
        Dir[File.join( pack_dir, '*' )].each do |smiley_file|
          smiley = File.basename( smiley_file, '.*' )
          res = define_file_resource( "webgen-emoticons-#{pack}-#{smiley}",
                                      smiley_file,
                                      "/images/emoticons/#{pack}-#{File.basename(smiley_file)}" )
          res.predefined = "Emoticon from pack '#{pack}' for '#{smiley}'"
        end
      end
    end

    def define_webgen_icons
      base_dir = File.join( Webgen.data_dir, 'resources', 'icons' )
      Dir[File.join( base_dir, '**/*')].each do |icon|
        dirs = File.dirname( icon ).sub( /^#{base_dir}/, '' ).split( '/' ).join( '-' )
        dirs += '-' if dirs.length > 0
        res = define_file_resource( "webgen-icons-#{dirs}#{File.basename( icon, '.*' )}",
                                    icon,
                                    "/images/icons/#{dirs}#{File.basename(icon)}" )
        res.predefined = "Icon named #{File.basename(icon)}"
      end
    end

    def define_user_resources
      p = param( 'resources' )
      if !p.kind_of?( Array ) || p.find {|h| !h.kind_of?( Array ) || h.length != 3}
        log(:error) { "Parameter 'resources' not correctly structured!" }
        return
      end
      p.each {|name, res_path, out_path| define_file_resource( name, res_path, out_path ) }
    end


    def write_resources
      temp = {}
      temp.update( self.class.infos[:resources] )
      temp.update( @resources )
      outDir = @plugin_manager.param_for_plugin( 'CorePlugins::Configuration', 'outDir' )

      temp.each do |name, res|
        if res.write_resource?( outDir )
          begin
            FileUtils.makedirs( File.dirname( res.dest_path( outDir ) ) )
            res.write_resource( outDir )
            log(:info) { "Resource '#{name}' written to <#{res.dest_path( outDir )}>" }
          rescue Exception => e
            log(:error) { "Error while writing resource '#{name}': #{e.message}" }
          end
        end
      end
    end

  end

end


module Tags

  class ResourceTag < DefaultTag

    infos(
          :summary => "Used for referencing resources",
          :description => "This tag can be used to output the path to a resource or the resource itself."
          )

    param 'name', nil, 'The name of the resource'
    param 'insert', :path, 'What should be returned by the tag: the path to the resource (value :path) ' +
      'or the data (value :data)'
    set_mandatory 'name', true

    register_tag 'resource'

    def process_tag( tag, chain )
      result = ''
      if res = @plugin_manager['CorePlugins::ResourceManager'].get_resource( param( 'name' ) )
        result = (param( 'insert' ) == :path ? res.referenced! && res.route_from( chain.last ) : res.data )
      else
        log(:error) { "Could not use resource #{param( 'name' )} as it does not exist!" }
      end
      result
    end

  end

end
