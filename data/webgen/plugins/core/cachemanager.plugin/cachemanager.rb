module Core

  # This plugin caches various information for the next webgen run, for example:
  #
  # * file modification times
  # * node meta information
  # * created files
  #
  # The parameter +keys+ for the various getter/setter method has to be an array of string/symbols
  # uniquely identifying a key.
  class CacheManager

    # The hash with the data from the last run
    attr_reader :data

    # The hash with the data from the current run that will be saved afterwards.
    attr_reader :new_data

    # Initializes the plugin and loads the cache file +webgen.cache+ from the website directory.
    def init_plugin
      cache_file = File.join( param( 'websiteDir', 'Core/Configuration' ), 'webgen.cache' )
      if File.exists?( cache_file )
        @data = Marshal.load( File.read( cache_file ) )
      else
        @data = {}
      end
      @new_data = {}
      @plugin_manager['Core/FileHandler'].add_msg_listener( :after_website_rendered ) do
        File.open( cache_file, 'wb' ) {|f| f.write( Marshal.dump( @new_data ) )}
      end
    end

    # Returns the value for +keys+ from the old webgen run and optonally sets the value of +keys+ to
    # +cur_val+ for the current webgen run. If +cur_val+ is not specified, no value is currently set
    # for +keys+ and a value from the old webgen run exists, then this value is used for +cur_val+.
    def get( keys, *cur_val )
      key = keys.join('/')
      if cur_val.empty?
        set( keys, @data[key] ) if @data.has_key?( key) && !@new_data.has_key?( key )
      else
        set( keys, cur_val.first )
      end
      @data[key]
    end

    # Sets the value of +keys+ to +value+.
    def set( keys, value )
      @new_data[keys.join('/')] = value
    end

    # Adds the +value+ to the array specified by +keys+.
    def add( keys, value )
      (@new_data[keys.join('/')] ||= []) << value
    end

  end

end
