module Core

  class CacheManager

    attr_reader :data

    def init_plugin
      cache_file = File.join( param( 'websiteDir', 'Core/Configuration' ), 'webgen.cache' )
      if File.exists?( cache_file )
        @data = Marshal.load( File.read( cache_file ) )
      else
        @data = {}
      end
      @new_data = {}
      @plugin_manager['Core/FileHandler'].add_msg_listener( :after_webgen_run ) do
        File.open( cache_file, 'wb' ) {|f| f.write( Marshal.dump( @new_data ) )}
      end
    end

    def get( keys, cur_val )
      set( keys, cur_val )
      @data[keys.join('/')]
    end

    def set( keys, value )
      @new_data[keys.join('/')] = value
    end

    def add( keys, value )
      (@new_data[keys.join('/')] ||= []) << value
    end

  end

end
