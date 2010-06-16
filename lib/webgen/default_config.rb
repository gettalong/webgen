# -*- encoding: utf-8 -*-

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
config.passive_sources([['/', "Webgen::Source::Resource", "webgen-passive-sources"]], :doc => 'One or more sources for delayed node creation on node resolution')

# All things regarding source handler
config.sourcehandler.patterns({
                                'Webgen::SourceHandler::Copy' => ['**/*.css', '**/*.js', '**/*.html', '**/*.gif', '**/*.jpg', '**/*.png', '**/*.ico'],
                                'Webgen::SourceHandler::Directory' => ['**/'],
                                'Webgen::SourceHandler::Metainfo' => ['**/metainfo', '**/*.metainfo'],
                                'Webgen::SourceHandler::Template' => ['**/*.template'],
                                'Webgen::SourceHandler::Page' => ['**/*.page'],
                                'Webgen::SourceHandler::Virtual' => ['**/virtual', '**/*.virtual'],
                                'Webgen::SourceHandler::Feed' => ['**/*.feed'],
                                'Webgen::SourceHandler::Sitemap' => ['**/*.sitemap']
                              }, :doc => 'Source handler to path pattern map')
config.sourcehandler.invoke({
                              1 => ['Webgen::SourceHandler::Directory', 'Webgen::SourceHandler::Metainfo'],
                              5 => ['Webgen::SourceHandler::Copy', 'Webgen::SourceHandler::Template',
                                    'Webgen::SourceHandler::Page', 'Webgen::SourceHandler::Feed',
                                    'Webgen::SourceHandler::Sitemap'],
                              9 => ['Webgen::SourceHandler::Virtual']
                            }, :doc => 'All source handlers listed here are used by webgen and invoked according to their priority setting')
config.sourcehandler.casefold(true, :doc => 'Specifies whether path are considered to be case-sensitive')
config.sourcehandler.use_hidden_files(false, :doc => 'Specifies whether hidden files (those starting with a dot) are used')
config.sourcehandler.ignore(['**/*~', '**/.svn/**'], :doc => 'Path patterns that should be ignored')
config.sourcehandler.default_lang_in_output_path(false, :doc => 'Specifies whether output paths in the default language should have the language in the name')

config.sourcehandler.default_meta_info({
                                         :all => {
                                           'output_path' => 'standard',
                                           'output_path_style' => [:parent, :basename, ['.', :lang], :ext]
                                         },
                                         'Webgen::SourceHandler::Copy' => {
                                           'kind' => 'asset'
                                         },
                                         'Webgen::SourceHandler::Directory' => {
                                           'index_path' => 'index.html',
                                           'kind' => 'directory'
                                         },
                                         'Webgen::SourceHandler::Page' => {
                                           'kind' => 'page',
                                           'fragments_in_menu' => true,
                                           'blocks' => {'default' => {'pipeline' => 'erb,tags,markdown,blocks,fragments'}}
                                         },
                                         'Webgen::SourceHandler::Fragment' => {
                                           'kind' => 'fragment'
                                         },
                                         'Webgen::SourceHandler::Template' => {
                                           'blocks' => {'default' => {'pipeline' => 'erb,tags,blocks,head'}}
                                         },
                                         'Webgen::SourceHandler::Metainfo' => {
                                           'blocks' => {1 => {'name' => 'paths'}, 2 => {'name' => 'alcn'}}
                                         },
                                         'Webgen::SourceHandler::Feed' => {
                                           'rss' => true,
                                           'atom' => true,
                                           'blocks' => {'default' => {'pipeline' => 'erb'}}
                                         },
                                         'Webgen::SourceHandler::Sitemap' => {
                                           'default_priority' => 0.5,
                                           'default_change_freq' => 'weekly',
                                           'common.sitemap.any_lang' => true,
                                           'blocks' => {'default' => {'pipeline' => 'erb'}}
                                         }
                                       }, :doc => "Default meta information for all nodes and for nodes belonging to a specific source handler")

config.sourcehandler.template.default_template('default.template', :doc => 'The name of the default template file of a directory')

website.autoload_service(:templates_for_node, 'Webgen::SourceHandler::Template')

website.autoload_service(:create_fragment_nodes, 'Webgen::SourceHandler::Fragment')
website.autoload_service(:parse_html_headers, 'Webgen::SourceHandler::Fragment')


# All things regarding output
config.output ["Webgen::Output::FileSystem", 'out'], :doc => 'The class which is used to output the generated paths.'
config.output.do_deletion(false, :doc => 'Specifies whether the generated output paths should be deleted once the sources are deleted')


Webgen::WebsiteAccess.website.blackboard.add_service(:output_instance, Webgen::Output.method(:instance))


# All things regarding content processors
config.contentprocessor.map({
                              'markdown' => 'Webgen::ContentProcessor::Kramdown',
                              'maruku' => 'Webgen::ContentProcessor::Maruku',
                              'textile' => 'Webgen::ContentProcessor::RedCloth',
                              'redcloth' => 'Webgen::ContentProcessor::RedCloth',
                              'tags' => 'Webgen::ContentProcessor::Tags',
                              'blocks' => 'Webgen::ContentProcessor::Blocks',
                              'erb' => 'Webgen::ContentProcessor::Erb',
                              'haml' => 'Webgen::ContentProcessor::Haml',
                              'sass' => 'Webgen::ContentProcessor::Sass',
                              'scss' => 'Webgen::ContentProcessor::Scss',
                              'rdoc' => 'Webgen::ContentProcessor::RDoc',
                              'builder' => 'Webgen::ContentProcessor::Builder',
                              'erubis' => 'Webgen::ContentProcessor::Erubis',
                              'rdiscount' => 'Webgen::ContentProcessor::RDiscount',
                              'fragments' => 'Webgen::ContentProcessor::Fragments',
                              'head' => 'Webgen::ContentProcessor::Head',
                              'tidy' => 'Webgen::ContentProcessor::Tidy',
                              'xmllint' => 'Webgen::ContentProcessor::Xmllint',
                              'kramdown' => 'Webgen::ContentProcessor::Kramdown',
                              'less' => 'Webgen::ContentProcessor::Less'
                            }, :doc => 'Content processor name to class map')

Webgen::WebsiteAccess.website.blackboard.add_service(:content_processor_names, Webgen::ContentProcessor.method(:list))
Webgen::WebsiteAccess.website.blackboard.add_service(:content_processor, Webgen::ContentProcessor.method(:for_name))
Webgen::WebsiteAccess.website.blackboard.add_service(:content_processor_binary?, Webgen::ContentProcessor.method(:is_binary?))

# All things regarding tags
config.contentprocessor.tags.prefix('', :doc => 'The prefix used for tag names to avoid name clashes when another content processor uses similar markup.')
config.contentprocessor.tags.map({
                                   'relocatable' => 'Webgen::Tag::Relocatable',
                                   'menu' => 'Webgen::Tag::Menu',
                                   'breadcrumb_trail' => 'Webgen::Tag::BreadcrumbTrail',
                                   'langbar' => 'Webgen::Tag::Langbar',
                                   'include_file' => 'Webgen::Tag::IncludeFile',
                                   'execute_cmd' => 'Webgen::Tag::ExecuteCommand',
                                   'coderay' => 'Webgen::Tag::Coderay',
                                   'date' => 'Webgen::Tag::Date',
                                   'sitemap' => 'Webgen::Tag::Sitemap',
                                   'tikz' => 'Webgen::Tag::TikZ',
                                   'link' => 'Webgen::Tag::Link',
                                   :default => 'Webgen::Tag::Metainfo'
                                 }, :doc => 'Tag processor name to class map')

config.contentprocessor.erubis.use_pi(false, :doc => 'Specifies whether processing instructions should be used')
config.contentprocessor.erubis.options({}, :doc => 'A hash of additional options')

config.contentprocessor.redcloth.hard_breaks(false, :doc => 'Specifies whether new lines are turned into hard breaks')

config.contentprocessor.tidy.options("-raw", :doc => "The options passed to the tidy command")

config.contentprocessor.xmllint.options("--catalogs --noout --valid", :doc => 'Options passed to the xmllint command')

config.contentprocessor.kramdown.options({:auto_ids => true}, :doc => 'The options hash for the kramdown processor')
config.contentprocessor.kramdown.handle_links(true, :doc => 'Whether all links in a kramdown document should be handled by webgen')


config.tag.metainfo.escape_html(true, :doc => 'Special HTML characters in the output will be escaped if true')

config.tag.relocatable.path(nil, :doc => 'The path which should be made relocatable', :mandatory => 'default')

config.tag.menu.start_level(1, :doc => 'The level at which the menu starts.')
config.tag.menu.min_levels(1, :doc => 'The minimum number of menu levels that should always be shown.')
config.tag.menu.max_levels(3, :doc => 'The maximum number of menu levels that should be shown.')
config.tag.menu.show_current_subtree_only(true, :doc => 'Specifies whether only the current subtree should be shown.')
config.tag.menu.used_nodes('all', :doc => 'Specifies the kind of nodes that should be used: all, files, or fragments')
config.tag.menu.nested(true, :doc => 'Specifies whether a nested menu list should be generated.')

config.tag.breadcrumbtrail.separator(' / ', :doc => 'Separates the hierachy entries from each other.')
config.tag.breadcrumbtrail.omit_index_path(false, :doc => 'Omits the last path component if it is an index path.')
config.tag.breadcrumbtrail.start_level(0, :doc => 'The level at which the breadcrumb trail starts.')
config.tag.breadcrumbtrail.end_level(-1, :doc => 'The level at which the breadcrumb trail ends.')

config.tag.langbar.separator(' | ', :doc => 'Separates the languages from each other.')
config.tag.langbar.show_single_lang(true, :doc => 'Should the link be shown although the page is only available in one language?')
config.tag.langbar.show_own_lang(true, :doc => 'Should the link to the currently displayed language page be shown?')
config.tag.langbar.lang_names({}, :doc => 'A map from language code to language names')
config.tag.langbar.process_output(false, :doc => 'The content of the language bar will be scanned for tags if true.')

config.tag.includefile.filename(nil, :doc => 'The name of the file which should be included (relative to the website).', :mandatory => 'default')
config.tag.includefile.process_output(true, :doc => 'The file content will be scanned for tags if true.')
config.tag.includefile.escape_html(true, :doc => 'Special HTML characters in the file content will be escaped if true.')

config.tag.executecommand.command(nil, :doc => 'The command which should be executed', :mandatory => 'default')
config.tag.executecommand.process_output(true, :doc => 'The output of the command will be scanned for tags if true')
config.tag.executecommand.escape_html(true, :doc => 'Special HTML characters in the output will be escaped if true')

config.tag.coderay.lang('ruby', :doc => 'The highlighting language', :mandatory => 'default')
config.tag.coderay.process_body(true, :doc => 'The tag body will be scanned for tags first if true')
config.tag.coderay.wrap(:div, :doc => 'Specifies how the code should be wrapped, either :div or :span')
config.tag.coderay.line_numbers(true, :doc => 'Show line numbers')
config.tag.coderay.line_number_start(1, :doc => 'Line number of first line')
config.tag.coderay.bold_every(10, :doc => 'The interval at which the line number appears bold')
config.tag.coderay.tab_width(8, :doc => 'Number of spaces used for a tabulator')
config.tag.coderay.css(:style, :doc => 'Specifies how the highlighted code should be styled')

config.tag.date.format('%Y-%m-%d %H:%M:%S', :doc => 'The format of the date (same options as Ruby\'s Time#strftime)')

config.tag.tikz.path(nil, :doc => 'The source path of the created image', :mandatory => 'default')
config.tag.tikz.libraries(nil, :doc => 'An array of additional TikZ library names')
config.tag.tikz.opts(nil, :doc => 'A string with global options for the tikzpicture environment')
config.tag.tikz.resolution('72 72', :doc => 'A string specifying the render and output resolutions')
config.tag.tikz.transparent(false, :doc => 'Specifies whether the generated image should be transparent (only png)')
config.tag.tikz.img_attr({}, :doc => 'A hash of additional HTML attributes for the created img tag')

config.tag.link.path(nil, :doc => 'The (A)LCN path to which a link should be generated', :mandatory => 'default')
config.tag.link.attr({}, :doc => 'A hash of additional HTML attributes that should be set on the link')

# All things regarding common functionality
website.autoload_service(:create_sitemap, 'Webgen::Common::Sitemap')

config.common.sitemap.honor_in_menu(false, :doc => 'Only include pages that are also in the menu if true')
config.common.sitemap.any_lang(false, :doc => 'Use nodes in any language if true')
config.common.sitemap.used_kinds(['page'], :doc => 'Array of node kinds that is used for the sitemap')
