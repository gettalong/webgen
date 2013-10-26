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

symbolic_hash = lambda do |val|
  raise 'The value has to be a hash' unless val.kind_of?(Hash)
  val.each_with_object({}) {|(k,v), h| h[k.to_sym] = v}
end

########################################################################
# General configuration parameters

option('website.tmpdir', 'tmp', &is_string)
option('website.cache', ['file', 'webgen.cache']) do |val|
  raise "The value has to be an array with two values" unless val.kind_of?(Array) && val.length == 2
  val.map! {|v| v.to_s}
  raise "The first value has to be 'file' or 'string'" unless val[0] == 'file' || val[0] == 'string'
  val
end
option('website.dry_run', false, &true_or_false)

option('website.lang', 'en') do |val|
  lang = LanguageManager.language_for_code(val)
  raise "Unknown language code '#{val}'" if lang.nil?
  lang
end

option('website.base_url', '', &is_string)
option('website.link_to_current_page', true, &true_or_false)

########################################################################
# Everything related to the content processor extension
require 'webgen/content_processor'

website.ext.content_processor = content_processor = Webgen::ContentProcessor.new
content_processor.register('Blocks')
content_processor.register('Builder')
content_processor.register('Erb')
option('content_processor.erb.trim_mode', '', &is_string)

content_processor.register('Erubis')
option('content_processor.erubis.use_pi', false, &true_or_false)
option('content_processor.erubis.options', {}, &symbolic_hash)

content_processor.register('Fragments')
content_processor.register('Haml', :ext_map => {'haml' => 'html'})
content_processor.register('HtmlHead')

content_processor.register('Kramdown')
option('content_processor.kramdown.options', {:auto_ids => true}, &symbolic_hash)
option('content_processor.kramdown.handle_links', true, &true_or_false)
option('content_processor.kramdown.ignore_unknown_fragments', false, &true_or_false)

content_processor.register('Maruku')

content_processor.register('Rainpress')
option('content_processor.rainpress.options', {}, &is_hash)

content_processor.register('RDiscount', :name => 'rdiscount')
content_processor.register('RDoc', :name => 'rdoc', :ext_map => {'rdoc' => 'html'})

content_processor.register('RedCloth', :name => 'redcloth', :ext_map => {'textile' => 'html'})
option('content_processor.redcloth.hard_breaks', false, &true_or_false)

content_processor.register('Ruby')

content_processor.register('Sass', :ext_map => {'sass' => 'css'})
content_processor.register('Scss', :ext_map => {'scss' => 'css'})
option('content_processor.sass.options', {}, &symbolic_hash)
website.ext.sass_load_paths = []

content_processor.register('Tags')

content_processor.register('Tidy')
option('content_processor.tidy.options', "-raw", &is_string)

content_processor.register('Tikz', :ext_map => {'tikz' => 'png'})
option('content_processor.tikz.libraries', [], &is_array)
option('content_processor.tikz.opts', '', &is_string)
option('content_processor.tikz.resolution', '72 72',) do |val|
  raise "The value has to be a string in the format 'RENDER_RES OUTPUT_RES'" unless val.kind_of?(String) && val =~ /^\d+\s+\d+$/
  val
end
option('content_processor.tikz.transparent', false, &true_or_false)
option('content_processor.tikz.template', '/templates/tikz.template', &is_string)

content_processor.register('Xmllint')
option('content_processor.xmllint.options', "--catalogs --noout --valid", &is_string)


########################################################################
# The Context extensions
website.ext.context_modules = []


########################################################################
# Everything related to the destination extension
require 'webgen/destination'

option('destination', ['file_system', 'out']) do |val|
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
website.blackboard.add_listener(:after_node_created, 'item_tracker.node_meta_info') do |node|
  item_tracker.add(node, :node_meta_info, node)
  item_tracker.add(node, :node_meta_info, node, Webgen::ItemTracker::NodeMetaInfo::CONTENT_MODIFICATION_KEY)
end

item_tracker.register('Nodes')
item_tracker.register('File')
item_tracker.register('MissingNode')
website.blackboard.add_listener(:node_resolution_failed, 'item_tracker.missing_node') do |path, lang|
  if website.ext.path_handler.current_dest_node
    website.ext.item_tracker.add(website.ext.path_handler.current_dest_node, :missing_node, path, lang)
    website.logger.error do
      ["Could not resolve '#{path}' in language '#{lang}' in <#{website.ext.path_handler.current_dest_node}>",
       "webgen will automatically try to resolve this error by rendering this path again later.",
       "If the error persists, the content of the path in question needs to be edited to correct the error."]
    end
  end
end

item_tracker.register('TemplateChain')

########################################################################
# The link definitions extension
website.ext.link_definitions = {}


########################################################################
# Miscellaneous extensions
website.ext.misc = OpenStruct.new

require 'webgen/misc/dummy_index'
website.ext.misc.dummy_index = Webgen::Misc::DummyIndex.new(website)
option('misc.dummy_index.enabled', true, &true_or_false)
option('misc.dummy_index.directory_indexes', ['index.html'])


########################################################################
# Everything related to the node finder extension
require 'webgen/node_finder'

website.ext.node_finder = Webgen::NodeFinder.new(website)
option('node_finder.option_sets', {})


########################################################################
# Everything related to the path handler extension
require 'webgen/path_handler'

option('path_handler.patterns.case_sensitive', false, &true_or_false)
option('path_handler.patterns.match_leading_dot', false, &true_or_false)
option('path_handler.lang_code_in_dest_path', 'except_default') do |val|
  if val == true || val == false || val == 'except_default'
    val
  else
    raise "The value has to be 'true', 'false' or 'except_default'"
  end
end
option('path_handler.version_in_dest_path', 'except_default') do |val|
  if val == true || val == false || val == 'except_default'
    val
  else
    raise "The value has to be 'true', 'false' or 'except_default'"
  end
end
option('path_handler.default_template', 'default.template')

website.ext.path_handler = path_handler = Webgen::PathHandler.new(website)

# handlers are registered in invocation order
path_handler.register('Directory')
path_handler.register('MetaInfo', :patterns => ['/**/metainfo', '/**/*.metainfo'])
path_handler.register('Template')
path_handler.register('Page')
path_handler.register('Copy')
path_handler.register('Feed')
path_handler.register('Sitemap')
path_handler.register('Virtual')
path_handler.register('Api')


########################################################################
# Everything related to the source extension
require 'webgen/source'

sources_validator = lambda do |val|
  raise "The value has to be an array of arrays" unless val.kind_of?(Array) && val.all? {|item| item.kind_of?(Array)}
  raise "Each sub array needs to specify at least the mount point and source extension name" unless val.all? {|item| item.length >= 2}
  val
end

option('sources', [['/', :file_system, 'src']], &sources_validator)
option('sources.ignore_paths', ['**/*~', '**/.svn/**', '**/.gitignore']) do |val|
  raise "The value has to be an array of patterns" unless val.kind_of?(Array) && val.all? {|item| item.kind_of?(String)}
  val
end

website.ext.source = source = Webgen::Source.new(website)
source.register("FileSystem")
source.register("Stacked")
source.register("TarArchive")

source.passive_sources << ['/', :file_system, File.join(Webgen::Utils.data_dir, 'passive_sources')]


########################################################################
# Everything related to the tag extension
require 'webgen/tag'

website.ext.tag = tag = Webgen::Tag.new(website)

option('tag.prefix', '', &is_string)

tag.register('Date')
option('tag.date.format', '%Y-%m-%d %H:%M:%S', &is_string)

tag.register('MetaInfo', :names => ['meta_info', :default])
option('tag.meta_info.escape_html', true, &true_or_false)
option('tag.meta_info.mi', nil, &is_string)

tag.register('Relocatable', :names => ['relocatable', 'r'], :mandatory => ['path'])
option('tag.relocatable.path', nil, &is_string)
option('tag.relocatable.ignore_unknown_fragment', false, &true_or_false)

tag.register('Link', :mandatory => ['path'])
option('tag.link.path', nil, &is_string)
option('tag.link.attr', {}, &is_hash)

tag.register('ExecuteCommand', :mandatory => ['command'])
option('tag.execute_command.command', nil, &is_string)
option('tag.execute_command.process_output', true, &true_or_false)
option('tag.execute_command.escape_html', true, &true_or_false)

tag.register('IncludeFile', :mandatory => ['filename'])
option('tag.include_file.filename', nil, &is_string)
option('tag.include_file.process_output', true, &true_or_false)
option('tag.include_file.escape_html', true, &true_or_false)

tag.register('Coderay', :mandatory => ['lang'])
option('tag.coderay.lang', 'ruby')
option('tag.coderay.process_body', true &true_or_false)
option('tag.coderay.wrap', 'div') do |val|
  val = val.to_s.intern
  raise "The value has to be either div or span" unless val == :div || val == :span
  val
end
option('tag.coderay.css', 'style')  do |val|
  val = val.to_s
  raise "The value has to be class, style or other" unless %w[class style other].include?(val)
  val
end
option('tag.coderay.line_numbers', true, &true_or_false)
option('tag.coderay.line_number_start', 1, &is_integer)
option('tag.coderay.bold_every', 10, &is_integer)
option('tag.coderay.tab_width', 8, &is_integer)

tag.register('Tikz', :mandatory => ['path'])
option('tag.tikz.path', nil, &is_string)
option('tag.tikz.img_attr', {}, &is_hash)

tag.register('Langbar')
option('tag.langbar.show_single_lang', true, &true_or_false)
option('tag.langbar.show_own_lang', true, &true_or_false)
option('tag.langbar.template', '/templates/tag.template')
option('tag.langbar.separator', ' | ')
option('tag.langbar.mapping', {}, &is_hash)

tag.register('BreadcrumbTrail')
option('tag.breadcrumb_trail.omit_dir_index', false &true_or_false)
option('tag.breadcrumb_trail.start_level', 0, &is_integer)
option('tag.breadcrumb_trail.end_level', -1, &is_integer)
option('tag.breadcrumb_trail.separator', ' / ', &is_string)
option('tag.breadcrumb_trail.template', '/templates/tag.template',)

tag.register('Menu')
option('tag.menu.style', 'nested') do |val|
  raise "The value has to be 'nested' or 'flat'" unless %w[nested flat].include?(val.to_s)
  val.to_s
end
option('tag.menu.options', {})
option('tag.menu.template', '/templates/tag.template')
option('tag.menu.css_class', nil)
option('tag.menu.item_level_class', 'webgen-menu-level')
option('tag.menu.item_submenu_class', 'webgen-menu-submenu')
option('tag.menu.item_submenu_inhierarchy_class', 'webgen-menu-submenu-inhierarchy')
option('tag.menu.item_selected_class', 'webgen-menu-item-selected')


########################################################################
# Everything related to the task extension
require 'webgen/task'

website.ext.task = task = Webgen::Task.new(website)
task.register('GenerateWebsite')
task.register('CreateWebsite', :data => {:templates => {}})
task.register('CreateBundle')


load("built-in-show-changes")
