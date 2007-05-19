require 'webgen/test'
require 'webgen/plugin'
require 'tmpdir'
require 'fileutils'

module Support

  class WebsiteManagerTest < Webgen::PluginTestCase

    plugin_to_test 'Support/WebsiteManager'

    def test_resource_class
      res = @plugin.templates['default']
      assert_equal( 2, res.files.length )
      with_tmpdir do |tmpdir|
        res.copy_to( tmpdir )
        check_copied_files( tmpdir, res.files, res.path )
      end
    end

    def test_create_website
      with_tmpdir do |tmpdir|
        assert_raise( ArgumentError ) { @plugin.create_website( tmpdir, 'not_existing_template' ) }
        assert_raise( ArgumentError ) { @plugin.create_website( tmpdir, 'default' ) }
        Dir.rmdir( tmpdir )
        @plugin.create_website( tmpdir, 'default' )
        res = @plugin.templates['default']
        check_copied_files( tmpdir, res.files, res.path )
      end
    end

    def test_use_style
      with_tmpdir do |tmpdir|
        Dir.rmdir( tmpdir )
        assert_raise( ArgumentError ) { @plugin.use_style( tmpdir, 'empty_category', 'not_existing_style' ) }
        assert_raise( ArgumentError ) { @plugin.use_style( tmpdir, 'website', 'default' ) }
        Dir.mkdir( tmpdir )
        @plugin.use_style( tmpdir, 'website', 'default' )
        res = @plugin.styles['website']['default']
        check_copied_files( tmpdir, res.files, res.path )
      end
    end

    def test_resources_changed
      nr_templates = @plugin.templates.length
      @manager.resources.delete( 'webgen/website/template/default' )
      assert( nr_templates - 1, @plugin.templates.length )
    end

    def test_templates
      assert( @plugin.templates.length > 0 )
    end

    def test_styles
      assert( @plugin.styles.length > 0 )
    end

    def with_tmpdir
      tmpdir = File.join( Dir::tmpdir, 'webgen' + $$.to_s + rand(5000).to_s )
      Dir.mkdir( tmpdir )
      yield tmpdir
    ensure
      FileUtils.rm_rf( tmpdir ) if tmpdir
    end

    def check_copied_files( dir, files, prefix )
      files.each do |file|
        assert( File.exists?( File.join( dir, file.sub(/^#{prefix}/, '') ) ) )
      end
    end

  end

end
