# -*- encoding: utf-8 -*-
#
# This file initializes all the extensions shipped with webgen.

########################################################################
# Used validators and other objects

true_or_false = lambda do |val|
  raise "The value has to be 'true' or 'false'" unless val == true || val == false
  val
end

is_string = lambda do |val|
  raise "The value has to be a string" unless val.kind_of?(String)
  val
end

is_array = lambda do |val|
  raise "The value has to be an array" unless val.kind_of?(Array)
  val
end

is_hash = lambda do |val|
  raise "The value has to be a hash" unless val.kind_of?(Hash)
  val
end

is_integer = lambda do |val|
  raise "The value has to be an integer" unless val.kind_of?(Integer)
  val
end

########################################################################
# General configuration parameters

option('website.tmpdir', 'tmp',
       'Storage location relative to website directory for cache and temporary files created when webgen is run', &is_string)
option('website.cache', [:file, 'webgen.cache'],
       'The file name relative to website.tmpdir (or a string) from/to which the cache is read/written') do |val|
  raise "The value has to be an array with two values" unless val.kind_of?(Array) && val.length == 2
  raise "The first value has to be :file or :string" unless val[0] == :file || val[0] == :string
  val
end

option('website.lang', 'en', 'The default language used for the website') do |val|
  lang = LanguageManager.language_for_code(val)
  raise "Unknown language code '#{val}'" if lang.nil?
  lang
end


########################################################################
# Everything related to the content processor extension
require 'webgen/content_processor'

website.ext.content_processor = content_processor = Webgen::ContentProcessor.new
content_processor.register('Blocks')
content_processor.register('Builder')
content_processor.register('Erb')

content_processor.register('Erubis')
option('content_processor.erubis.use_pi', false,
       'Specifies whether processing instructions should be used', &true_or_false)
option('content_processor.erubis.options', {},
       'A hash of additional, erubis specific options')

content_processor.register('Fragments')
content_processor.register('Haml', :ext_map => {'haml' => 'html'})
content_processor.register('HtmlHead')

content_processor.register('Kramdown')
option('content_processor.kramdown.options', {:auto_ids => true},
       'The options hash for the kramdown processor')
option('content_processor.kramdown.handle_links', true,
       'Whether all links in a kramdown document should be processed by webgen', &true_or_false)

content_processor.register('Maruku')
content_processor.register('RDiscount', :name => 'rdiscount')
content_processor.register('RDoc', :name => 'rdoc', :ext_map => {'rdoc' => 'html'})

content_processor.register('RedCloth', :name => 'redcloth', :ext_map => {'textile' => 'html'})
option('content_processor.redcloth.hard_breaks', false,
       'Specifies whether new lines are turned into hard breaks', &true_or_false)

content_processor.register('Ruby')

content_processor.register('Sass', :ext_map => {'sass' => 'css'})
content_processor.register('Scss', :ext_map => {'scss' => 'css'})
option('content_processor.sass.options', {},
       'Additional Sass options (also used by the scss processor)', &is_hash)
website.ext.sass_load_paths = []

content_processor.register('Tags')

content_processor.register('Tidy')
option('content_processor.tidy.options', "-raw",
       "Additional options passed to the tidy command (-q and -f are always used)", &is_string)

content_processor.register('Tikz', :ext_map => {'tikz' => 'png'})
option('content_processor.tikz.libraries', [],
       'An array of additional TikZ library names', &is_array)
option('content_processor.tikz.opts', '',
       'A string with global options for the tikzpicture environment', &is_string)
option('content_processor.tikz.resolution', '72 72',
       'A string specifying the render and output resolutions, separated by whitespace') do |val|
  raise "The value has to be a string in the format 'RENDER_RES OUTPUT_RES'" unless val.kind_of?(String) && val =~ /^\d+\s+\d+$/
  val
end
option('content_processor.tikz.transparent', false,
       'Specifies whether the generated image should be transparent (only if the extension is png)', &true_or_false)

content_processor.register('Xmllint')
option('content_processor.xmllint.options', "--catalogs --noout --valid",
       'Options passed to the xmllint command', &is_string)


########################################################################
# The Context extensions
website.ext.context_modules = []


########################################################################
# Everything related to the destination extension
require 'webgen/destination'

option('destination', [:file_system, 'out'],
       'The destination extension which is used to output the generated paths.') do |val|
  raise "The value needs to be an array with at least one value (the destination extension name)" unless val.kind_of?(Array) && val.length >=1
  val
end

website.ext.destination = destination = Webgen::Destination.new(website)
destination.register("FileSystem")

# TODO: Do we really need this option?
#config.output.do_deletion(false, :doc => 'Specifies whether the generated output paths should be deleted once the sources are deleted')


########################################################################
# Everything related to the item tracker extension
require 'webgen/item_tracker'

website.ext.item_tracker = item_tracker = Webgen::ItemTracker.new(website)
item_tracker.register('NodeContent')

item_tracker.register('NodeMetaInfo')
website.blackboard.add_listener(:after_node_created) do |node|
  item_tracker.add(node, :node_meta_info, node.alcn)
end

item_tracker.register('Nodes')
item_tracker.register('File')
item_tracker.register('MissingNode')


########################################################################
# Everything related to the node finder extension
require 'webgen/node_finder'

website.ext.node_finder = Webgen::NodeFinder.new(website)


########################################################################
# Everything related to the path handler extension
require 'webgen/path_handler'

option('path_handler.patterns.case_sensitive', false,
       'Specifies whether patterns are considered to be case sensitive', &true_or_false)
option('path_handler.patterns.match_leading_dot', false,
       'Specifies whether paths parts starting with a dot are matched', &true_or_false)
option('path_handler.lang_code_in_dest_path', 'except_default',
       'Specifies whether destination paths should use the language part in their name') do |val|
  if val == true || val == false || val == 'except_default'
    val
  else
    raise "The value has to be 'true', 'false' or 'except_default'"
  end
end
option('path_handler.version_in_dest_path', 'except_default',
       'Specifies whether destination paths should use the version name in their name') do |val|
  if val == true || val == false || val == 'except_default'
    val
  else
    raise "The value has to be 'true', 'false' or 'except_default'"
  end
end

option('path_handler.default_meta_info',
       {
         :all => {
           'dest_path' => '<parent><basename>(-<version>)(.<lang>)<ext>',
         },
         'directory' => {
           'index_path' => 'index.html',
         },
         'template' => {
           'no_output' => true,
           'blocks' => {:default => {'pipeline' => 'erb,tags,blocks,html_head'}}
         },
         'page' => {
           'blocks' => {:default => {'pipeline' => 'erb,tags,kramdown,blocks,fragments'}}
         },
         'meta_info' => {
           'no_output' => true,
           'blocks' => {1 => {'name' => 'paths'}, 2 => {'name' => 'alcn'}}
         },
         'feed' => {
           'rss' => true,
           'atom' => true,
           'blocks' => {:default => {'pipeline' => 'erb'}}
         },
         'sitemap' => {
           'default_priority' => 0.5,
           'default_change_freq' => 'weekly',
           'blocks' => {1 => {'name' => 'sitemap', 'pipeline' => 'erb'}}
         },
       },
       'Default meta information for all nodes (key :all) and for nodes belonging to a specific path handler') do |val|
  raise "The value has to be a hash" unless val.kind_of?(Hash)
  cur_val = website.config['path_handler.default_meta_info']
  val.each do |handler, mi|
    raise "The value for each key has to be a hash" unless mi.kind_of?(Hash)
    action = ((mi.delete(:action) || 'modify') == 'modify' ? :update : :replace)
    (cur_val[handler] ||= {}).send(action, mi)
  end
  cur_val
end

website.ext.path_handler = path_handler = Webgen::PathHandler.new(website)

# handlers are registered in invocation order

path_handler.register('Directory', :patterns => ['**/'])
path_handler.register('MetaInfo', :patterns => ['**/metainfo', '**/*.metainfo'])

path_handler.register('Template', :patterns => ['**/*.template'])
option('path_handler.template.default_template', 'default.template',
       'The name of the default template file')

path_handler.register('Page', :patterns => ['**/*.page'])

path_handler.register('Copy')
option('path_handler.copy.patterns',
       ['**/*.css', '**/*.js', '**/*.html', '**/*.gif', '**/*.jpg', '**/*.png', '**/*.ico'],
       'The path patterns for the paths that should just be copied to the destination') do |val|
  raise "The value has to be an array of path patterns (strings)" unless val.kind_of?(Array) && val.all? {|i| i.kind_of?(String)}
  val
end
website.blackboard.add_listener(:website_initialized) do
  patterns = content_processor.extension_map.keys.map {|pattern| "**/*.#{pattern}"}
  path_handler.registered_extensions[:copy].patterns += patterns
end

path_handler.register('Feed', :patterns => ['**/*.feed'])
path_handler.register('Sitemap', :patterns => ['**/*.sitemap'])
path_handler.register('Virtual', :patterns => ['**/virtual', '**/*.virtual'])


########################################################################
# Everything related to the source extension
require 'webgen/source'

sources_validator = lambda do |val|
  raise "The value has to be an array of arrays" unless val.kind_of?(Array) && val.all? {|item| item.kind_of?(Array)}
  raise "Each sub array needs to specify at least the mount point and source extension name" unless val.all? {|item| item.length >= 2}
  val
end

option('sources', [['/', :file_system, 'src']],
       'One or more sources from which paths are read', &sources_validator)
option('sources.passive', [['/', :file_system, File.join(Webgen::Utils.data_dir, 'passive_sources')]],
       'One or more sources from which paths are read that are only used when referenced ', &sources_validator)
option('sources.ignore_paths', ['**/*~', '**/.svn/**'],
       'Patterns for paths that should be ignored') do |val|
  raise "The value has to be an array of patterns" unless val.kind_of?(Array) && val.all? {|item| item.kind_of?(String)}
  val
end

website.ext.source = source = Webgen::Source.new(website)
source.register("FileSystem")
source.register("Stacked")
source.register("TarArchive")


########################################################################
# Everything related to the tag extension
require 'webgen/tag'

website.ext.tag = tag = Webgen::Tag.new(website)

option('tag.prefix', '',
       'The prefix used for tag names to avoid name clashes when another content processor uses similar markup.',
       &is_string)

tag.register('Date')
option('tag.date.format', '%Y-%m-%d %H:%M:%S',
       'The format of the date (same options as Ruby\'s Time#strftime)', &is_string)

tag.register('MetaInfo', :names => :default)
option('tag.meta_info.escape_html', true,
       'Special HTML characters in the output will be escaped if true', &true_or_false)

tag.register('Relocatable', :names => ['relocatable', 'r'], :mandatory => ['path'])
option('tag.relocatable.path', nil,
       'The path which should be made relocatable', &is_string)

tag.register('Link', :mandatory => ['path'])
option('tag.link.path', nil,
       'The (A)LCN path to which a link should be generated', &is_string)
option('tag.link.attr', {},
       'A hash of additional HTML attributes that should be set on the link', &is_hash)

tag.register('ExecuteCommand', :names => 'execute_cmd', :mandatory => ['command'])
option('tag.execute_command.command', nil,
       'The command which should be executed', &is_string)
option('tag.execute_command.process_output', true,
       'The output of the command will be scanned for tags if true', &true_or_false)
option('tag.execute_command.escape_html', true,
       'Special HTML characters in the output will be escaped if true', &true_or_false)

tag.register('IncludeFile', :mandatory => ['filename'])
option('tag.include_file.filename', nil,
       'The name of the file which should be included (relative to the website).', &is_string)
option('tag.include_file.process_output', true,
       'The file content will be scanned for tags if true.', &true_or_false)
option('tag.include_file.escape_html', true,
       'Special HTML characters in the file content will be escaped if true.', &true_or_false)

tag.register('Coderay', :mandatory => ['lang'])
option('tag.coderay.lang', 'ruby',
       'The language used for highlighting')
option('tag.coderay.process_body', true,
       'The tag body will be scanned for tags before highlighting if true', &true_or_false)
option('tag.coderay.wrap', :div,
       'Specifies how the code should be wrapped, either "div" or "span"') do |val|
  val = val.to_s.intern
  raise "The value has to be either div or span" unless val == :div || val == :span
  val
end
option('tag.coderay.css', 'style',
       'Specifies how the highlighted code should be styled')  do |val|
  val = val.to_s
  raise "The value has to be class, style or other" unless %w[class style other].include?(val)
  val
end
option('tag.coderay.line_numbers', true,
       'Show line numbers', &true_or_false)
option('tag.coderay.line_number_start', 1,
       'Line number of first line', &is_integer)
option('tag.coderay.bold_every', 10,
       'The interval at which the line number appears bold', &is_integer)
option('tag.coderay.tab_width', 8,
       'Number of spaces used for a tabulator', &is_integer)

tag.register('Tikz', :mandatory => ['path'])
option('tag.tikz.path', nil,
       'The path for the created image', &is_string)
option('tag.tikz.img_attr', {},
       'A hash of additional HTML attributes for the created img tag', &is_hash)

tag.register('Langbar')
option('tag.langbar.show_single_lang', true,
       'Should the link be shown although the page is only available in one language?', &true_or_false)
option('tag.langbar.show_own_lang', true,
       'Should the link to the currently displayed language page be shown?', &true_or_false)
option('tag.langbar.template', '/templates/tag.template',
       'The block \'tag.langbar\' in this template file is used for rendering')

tag.register('BreadcrumbTrail')
option('tag.breadcrumb_trail.omit_dir_index', false,
       'Omit the last path component if it is an index path', &true_or_false)
option('tag.breadcrumb_trail.start_level', 0,
       'The level at which the breadcrumb trail starts (starting at 0)', &is_integer)
option('tag.breadcrumb_trail.end_level', -1,
       'The level at which the breadcrumb trail ends (starting at 0).', &is_integer)
option('tag.breadcrumb_trail.template', '/templates/tag.template',
       'The block \'tag.breadcrumb_trail\' in this template file is used for rendering')

#TODO: tag.register('Menu')
#TODO: tag.register('Sitemap')
