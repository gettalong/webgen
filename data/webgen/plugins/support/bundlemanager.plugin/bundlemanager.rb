require 'yaml'
require 'open-uri'
require 'fileutils'
require 'facets/minitar'
require 'zlib'
require 'facets/version'
require 'stringio'

module Support

  # This plugin is used for managing webgen plugin bundles. For information on how to create plugin
  # bundles have a look at the Webgen::Plugin documentation.
  #
  # = General information
  #
  # The plugin provides a list of the available repositories and their bundles in the +repository+
  # attribute. For more information on the available data have a look at the respective classes.
  #
  # The following actions on bundles are supported:
  #
  # * installing a bundle from a repository (#install_bundle)
  # * removing an installed bundle (#remove_bundle)
  # * packaging a bundle for distribution (#package_bundle)
  # * updating the local list of repositories and available bundles (#update_repositories)
  class BundleManager

    # Describes one plugin contained in a bundle.
    class PluginInfo

      # The name of the plugin.
      attr_reader :name

      # The plugin author.
      attr_reader :author

      # A short summary of the functionality of the plugin.
      attr_reader :summary

      # A detailed description of the plugin.
      attr_reader :description

      # Additional infos provided by the plugin author.
      attr_reader :infos

      def initialize( name, hash )
        @name = name
        @author = hash.delete( 'author' )
        @summary = hash.delete( 'summary' )
        @description = hash.delete( 'description' )
        @infos = hash
      end

      def <=>( other )
        self.name <=> other.name
      end

    end

    ResourceInfo = Struct.new( :name, :description )

    # Describes a resource contained in a bundle. Use the +name+ and +description+ attributes for
    # retrieving information about the resource.
    class ResourceInfo

      def <=>( other )
        self.name <=> other.name
      end

    end

    # Describes a bundle which can be contained in a repository or it can only be available locally.
    class Bundle

      # The name of the bundle.
      attr_reader :name

      # A short summary of the functionality of the bundle.
      attr_reader :summary

      # The status is <tt>:installed</tt> if the bundle is installed or <tt>:available</tt>
      # otherwise.
      attr_reader :status

      # The path where the bundle is installed or +nil+ otherwise.
      attr_reader :install_path

      # The version of the bundle.
      attr_reader :version

      # A version constraint describing with which version of webgen this bundle works.
      attr_reader :webgen_version

      # The repository which hosts this bundle or the special repository named <tt>:local</tt> if
      # the bundle is only locally available.
      attr_reader :repository

      # An array of plugins the bundle contains.
      attr_reader :plugins

      # An array of resources the bundle contains.
      attr_reader :resources

      def initialize( hash, repository, install_path = nil)
        @name = hash['name']
        @summary = hash['summary']
        @version = hash['version']
        @webgen_version = hash['webgen-version']
        @repository = repository
        @repository.bundles << self
        @install_path = install_path
        @status = (install_path.nil? ? :available : :installed)
        @plugins = hash['plugins'].collect {|name, data| PluginInfo.new( name, data )}
        @resources = hash['resources'].collect {|name, desc| ResourceInfo.new( name, desc )}
      end

      # The package name for the bundle.
      def package_name
        "#{name}-#{version}.tgz"
      end

      # Set the install path to +path+ and updates the status accordingly.
      def set_install_path( path )
        @install_path = path
        @status = (path.nil? ? :available : :installed)
      end

      def <=>( other )
        self.name <=> other.name
      end

      # Extracts all necessary information from the bundle at +path+ and returns a hash which can be
      # used as parameter for the #initialize method.
      def self.extract_bundle_infos( path )
        pm = Webgen::PluginManager.new( [], nil )
        pm.load_plugin_bundle( path )

        bundle_infos = YAML::load( File.read( File.join( path, 'bundle.yaml' ) ) ) rescue {}
        bundle_infos['version'] ||= '0.0.0'
        bundle_infos['webgen-version'] ||= Webgen::VERSION.join('.')
        bundle_infos['name'] = File.basename( path, '.plugin' )

        bundle_infos['plugins'] = {}
        pm.plugin_infos.each {|plugin_name, infos| bundle_infos['plugins'][plugin_name] = infos['about']}
        bundle_infos['resources'] = {}
        pm.resources.each do |res_name, infos|
          bundle_infos['resources'][res_name] = infos['desc'].to_s
        end
        bundle_infos
      end

    end

    Repository = Struct.new( :uri, :description, :bundles )

    # Describes a repository. Use the +uri+, +description+ and +bundles+ attributes to get
    # information about the repository.
    class Repository

      def <=>( other )
        self.uri.to_s <=> other.uri.to_s
      end

    end

    # The main repository list.
    REPO_LIST_URL = 'http://webgen.rubyforge.org/repositories.yaml'

    # The name of the file in which information about a repository is stored.
    INFO_FILENAME = 'webgen-bundles.yaml'

    REPO_FILE = File.join( Webgen.home_dir, 'plugin-bundle-repositories.yaml' )
    PLUGIN_INFO_FILE = File.join( Webgen.home_dir, 'plugin-bundle-infos.yaml' )
    PLUGIN_HOME_DIR = File.join( Webgen.home_dir, Webgen::PLUGIN_DIR )

    # A list of all available repositories.
    attr_reader :repositories

    def init_plugin
      load_repositories
    end

    # Installs the bundle called +name+ in the specified +target+, optionally using the specified
    # +version+. The +target+ can be one of the following:
    #
    # <tt>:website</tt>:: Install the bundle in the website specific plugins directory
    # <tt>:home</tt>:: Install the bundle in the user specific plugins directory.
    def install_bundle( name, version = nil, target = :website )
      bundles = []
      repositories.each do |repo|
        repo.bundles.each do |bundle|
          bundles << bundle if bundle.name == name && (version.nil? || bundle.version == version)
        end
      end

      bundle = bundles.sort {|a,b| a.version <=> b.version}.last

      target_dir = (target == :website ? File.join( @plugin_manager.param( 'websiteDir', 'Core/Configuration' ), Webgen::PLUGIN_DIR ) : PLUGIN_HOME_DIR)
      target_name = name + '.plugin'
      if File.exists?( File.join( target_dir, target_name ) )
        yield( :failed, "There is already a plugin bundle called #{target_name} installed in <#{target_dir}>." ) if block_given?
        return
      end
      if bundle.nil?
        yield( :failed, "No bundle named #{name} found")
        return
      end

      data = ''
      begin
        open( File.join( bundle.repository.uri, bundle.package_name ) ) {|f| data = f.read}
      rescue
        yield( :failed, $!.message ) if block_given?
        return
      end

      tgz = Zlib::GzipReader.new( StringIO.new( data ) )
      Archive::Tar::Minitar.unpack( tgz, target_dir )
      yield( :succeeded, '' )

      load_repositories
    end

    # Removes the bundle called +name+. If more than one bundle called +name+ are installed, the one
    # with the lowest version number is removed.
    def remove_bundle( name )
      bundles = []
      repositories.each do |repo|
        repo.bundles.each do |bundle|
          bundles << bundle if bundle.name == name && bundle.status == :installed
        end
      end

      bundle = bundles.sort {|a,b| a.version <=> b.version}.first
      if bundle
        FileUtils.rm_rf( bundle.install_path )
        load_repositories
        yield( :succeeded, '' )
      else
        yield( :failed, 'No plugin bundle with this name found')
      end
    end

    # Packages the bundle at +path+ and adds the needed information and the packaged bundle to the
    # +repository+ which has to be the path to a repository. If the repository does not exist, it is
    # created.
    def package_bundle( path, repository )
      bundle_infos = Bundle.extract_bundle_infos( path )

      info_file = File.join( repository, INFO_FILENAME )
      repo_infos = YAML::load( File.read( info_file ) ) rescue []

      repo_infos.delete_if {|data| data['name'] == bundle_infos['name'] && data['version'] == bundle_infos['version'] }
      repo_infos << bundle_infos

      FileUtils.mkdir_p( repository )
      tgz = Zlib::GzipWriter.new( File.open( File.join( repository, "#{bundle_infos['name']}-#{bundle_infos['version']}.tgz" ), 'wb' ) )
      Dir.chdir( File.dirname( path ) ) do
        Archive::Tar::Minitar.pack( File.basename( path ), tgz )
      end

      File.open( info_file, 'w+' ) {|f| f.write(repo_infos.to_yaml) }
    end

    # Updates the local list of repositories.
    def update_repositories
      repos = YAML::load( File.read( REPO_FILE  ) ) rescue {}
      infos = YAML::load( File.read( PLUGIN_INFO_FILE  ) ) rescue {}

      begin
        open( REPO_LIST_URL ) {|f| repos.update( YAML::load( f.read ) ) }
      rescue
        yield( :repos, :failed, $!.message ) if block_given?
      else
        yield( :repos, :succeeded, '' ) if block_given?
      end
      FileUtils.mkdir_p( File.dirname( REPO_FILE ) )
      File.open( REPO_FILE, 'w+' ) {|f| f.write(repos.to_yaml) }

      repos.each do |repo, desc|
        begin
          open( File.join( repo, INFO_FILENAME ) ) {|f| infos[repo] = YAML::load( f.read ) }
        rescue
          yield( repo, :failed, $!.message ) if block_given?
        else
          yield( repo, :succeeded, '' ) if block_given?
        end
        infos[repo] = [] unless infos[repo].kind_of?( Array )
      end
      FileUtils.mkdir_p( File.dirname( PLUGIN_INFO_FILE ) )
      File.open( PLUGIN_INFO_FILE, 'w+' ) {|f| f.write(infos.to_yaml) }
      load_repositories
    end

    #######
    private
    #######

    def load_repositories
      @repositories = (YAML::load( File.read( REPO_FILE  ) ) rescue {}).
        collect {|uri, desc| Repository.new( uri, desc, [] )}
      @repositories << Repository.new( :local, 'Bundles not installed from a repository', [] )
      load_bundle_infos
    end

    def load_bundle_infos
      temp_bundle_infos = (YAML::load( File.read( PLUGIN_INFO_FILE  ) ) rescue {}).collect do |uri, bundles|
        repo = @repositories.find {|r| r.uri == uri} || @repositories.last
        bundles.collect {|bundle| Bundle.new( bundle, repo )}
      end.flatten
      [PLUGIN_HOME_DIR, File.join( param( 'websiteDir', 'Core/Configuration' ), Webgen::PLUGIN_DIR )].each do |path|
        Dir[File.join( path, '*.plugin' )].each do |bundle_path|
          bundle_infos = Bundle.extract_bundle_infos( bundle_path )
          bundle = temp_bundle_infos.find {|b| b.name == bundle_infos['name'] && b.version == bundle_infos['version']}
          if bundle
            bundle.set_install_path( bundle_path )
          else
            Bundle.new( bundle_infos, @repositories.last, bundle_path )
          end
        end
      end
    end

  end

end
