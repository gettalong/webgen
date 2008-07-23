website = Webgen::WebsiteAccess.website
config = website.config

# General configuration parameters
config.website.cache([:file, 'webgen.cache'], :doc => 'The file name (or String) from/to which the cache is read/written')
config.website.lang('en', :doc => 'The default language used for the website')
config.website.link_to_current_page(false, :doc => 'Specifies whether links to the current page should be used')

# All things regarding logging
config.logger.mask(nil, :doc => 'Only show logging events which match the regexp mask')


# All things regarding resources
config.resources({}, :doc => 'A mapping from resource names to source identifiers')

resources = YAML::load(File.read(File.join(Webgen.data_dir, 'resources.yaml')))
resources.each do |res_path_template, res_name|
  Dir.glob(File.join(Webgen.data_dir, res_path_template), File::FNM_CASEFOLD).each do |res_path|
    substs = Hash.new {|h,k| h[k] = "$" + k }
    substs.merge!({
                    'basename' => File.basename(res_path),
                    'basename_no_ext' => File.basename(res_path, '.*'),
                    'extname' => File.extname(res_path)[1..-1],
                    :dirnames => File.dirname(res_path).split(File::SEPARATOR),
                  })
    name = res_name.to_s.gsub(/\$\w+/) do |m|
      if m =~ /^\$dir(\d+)$/
        substs[:dirnames][-($1.to_i)]
      else
        substs[m[1..-1]]
      end
    end
    config['resources'][name] = if File.directory?(res_path)
                                  ["Webgen::Source::FileSystem", res_path]
                                else
                                  ["Webgen::Source::FileSystem", File.dirname(res_path), File.basename(res_path)]
                                 end
  end
end


# All things regarding sources
config.sources [['/', "Webgen::Source::FileSystem", 'src']], :doc => 'One or more sources from which files are read, relative to website directory'

# All things regarding source handler
config.sourcehandler.patterns({
                                'Webgen::SourceHandler::Copy' => ['**/*.css', '**/*.js', '**/*.html', '**/*.gif', '**/*.jpg', '**/*.png'],
                                'Webgen::SourceHandler::Directory' => ['**/'],
                                'Webgen::SourceHandler::Metainfo' => ['**/metainfo', '**/*.metainfo'],
                                'Webgen::SourceHandler::Template' => ['**/*.template'],
                                'Webgen::SourceHandler::Page' => ['**/*.page'],
                                'Webgen::SourceHandler::Virtual' => ['**/virtual', '**/*.virtual']
                              }, :doc => 'Source handler to path pattern map')
config.sourcehandler.invoke({
                              1 => ['Webgen::SourceHandler::Directory', 'Webgen::SourceHandler::Metainfo', 'Webgen::SourceHandler::Directory'],
                              5 => ['Webgen::SourceHandler::Copy', 'Webgen::SourceHandler::Template', 'Webgen::SourceHandler::Page'],
                              9 => ['Webgen::SourceHandler::Virtual']
                            }, :doc => 'All source handlers listed here are used by webgen and invoked according to their priority setting')
config.sourcehandler.casefold(true, :doc => 'Specifies whether path are considered to be case-sensitive')
config.sourcehandler.use_hidden_files(false, :doc => 'Specifies whether hidden files (those starting with a dot) are used')
config.sourcehandler.ignore(['**/*~', '**/.svn/**'], :doc => 'Path patterns that should be ignored')
config.sourcehandler.default_lang_in_output_path(false, :doc => 'Specifies whether output paths in the default language should have the language in the name')
=begin
TODO:put this info into the user docs
      desc: Defines how the output name should be built. The correct name will be used for the
            :basename part and the file language will be used for the :lang part. If defaultLangInFilename
            is true, the :lang part or the subarray in which the :lang part was defined, will be omitted.
            The :ext part is replaced with the correct extension.
=end
config.sourcehandler.default_meta_info({
                                         :all => {
                                           'output_path_style' => [:parent, :cnbase, ['.', :lang], :ext]
                                         },
                                         'Webgen::SourceHandler::Directory' => {
                                           'index_path' => 'index.html'
                                         },
                                         'Webgen::SourceHandler::Page' => {
                                           'fragments_in_menu' => true,
                                           'blocks' => {'default' => {'pipeline' => 'erb,tags,maruku,blocks'}}
                                         },
                                         'Webgen::SourceHandler::Template' => {
                                           'blocks' => {'default' => {'pipeline' => 'erb,tags,blocks'}}
                                         },
                                         'Webgen::SourceHandler::Metainfo' => {
                                           'blocks' => {1 => {'name' => 'paths'}, 2 => {'name' => 'alcn'}}
                                         }
                                       }, :doc => "Default meta information for all nodes and for nodes belonging to a specific source handler")

config.sourcehandler.template.default_template('default.template', :doc => 'The name of the default template file of a directory')

website.autoload_service(:templates_for_node, 'Webgen::SourceHandler::Template')

website.autoload_service(:create_fragment_nodes, 'Webgen::SourceHandler::Fragment')
website.autoload_service(:parse_html_headers, 'Webgen::SourceHandler::Fragment')


# All things regarding output
config.output ["Webgen::Output::FileSystem", 'out'], :doc => 'The class which is used to output the generated paths.'

Webgen::WebsiteAccess.website.blackboard.add_service(:output_instance, Webgen::Output.method(:instance))


# All things regarding content processors
config.contentprocessor.map({
                              'maruku' => 'Webgen::ContentProcessor::Maruku',
                              'redcloth' => 'Webgen::ContentProcessor::RedCloth',
                              'tags' => 'Webgen::ContentProcessor::Tags',
                              'blocks' => 'Webgen::ContentProcessor::Blocks',
                              'erb' => 'Webgen::ContentProcessor::Erb',
                              'haml' => 'Webgen::ContentProcessor::Haml',
                              'sass' => 'Webgen::ContentProcessor::Sass',
                              'rdoc' => 'Webgen::ContentProcessor::RDoc',
                              'builder' => 'Webgen::ContentProcessor::Builder',
                            }, :doc => 'Content processor name to class map')

Webgen::WebsiteAccess.website.blackboard.add_service(:content_processor_names, Webgen::ContentProcessor.method(:list))
Webgen::WebsiteAccess.website.blackboard.add_service(:content_processor, Webgen::ContentProcessor.method(:for_name))

# All things regarding tags
config.contentprocessor.tags.prefix('', :doc => 'The prefix used for tag names to avoid name clashes when another content processor uses similar markup.')
config.contentprocessor.tags.map({
                                   'relocatable' => 'Webgen::Tag::Relocatable',
                                   'menu' => 'Webgen::Tag::Menu',
                                   'breadcrumb_trail' => 'Webgen::Tag::BreadcrumbTrail',
                                   'langbar' => 'Webgen::Tag::Langbar',
                                   :default => 'Webgen::Tag::Metainfo'
                                 }, :doc => 'Tag processor name to class map')

config.tag.relocatable.path(nil, :doc => 'The path which should be made relocatable', :mandatory => 'default')

config.tag.menu.start_level(1, :doc => 'The level at which the menu starts.')
config.tag.menu.min_levels(1, :doc => 'The minimum number of menu levels that should always be shown.')
config.tag.menu.max_levels(3, :doc => 'The maximum number of menu levels that should be shown.')
config.tag.menu.show_current_subtree_only(true, :doc => 'Specifies whether only the current subtree should be shown.')
config.tag.menu.used_nodes('all', :doc => 'Specifies the kind of nodes that should be used: all, files, or fragments')

config.tag.breadcrumbtrail.separator(' / ', :doc => 'Separates the hierachy entries from each other.')
config.tag.breadcrumbtrail.omit_last(false, :doc => 'Omits the last path component.')
config.tag.breadcrumbtrail.omit_index_path(false, :doc => 'Omits the last path component if it is an index path.')

config.tag.langbar.separator(' | ', :doc => 'Separates the languages from each other.')
config.tag.langbar.show_single_lang(true, :doc => 'Should the link be shown although the page is only available in one language?')
config.tag.langbar.show_own_lang(true, :doc => 'Should the link to the currently displayed language page be shown?')

