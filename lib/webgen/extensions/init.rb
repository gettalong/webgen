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

author = 'Thomas Leitner <t_leitner@gmx.at>'

########################################################################
# General configuration parameters
option('website.cache', [:file, 'webgen.cache'],
       'The file name (or string) from/to which the cache is read/written') do |val|
  raise "The value has to be an array with two values" unless val.kind_of?(Array) && val.length == 2
  raise "The first value has to be :file or :string" unless val[0] == :file || val[0] == :string
  val
end

option('website.lang', 'en', 'The default language used for the website') do |val|
  lang = LanguageManager.language_for_code(val)
  raise "Unknown language code '#{val}'" if lang.nil?
  lang
end

#TODO
#config.website.link_to_current_page(false, :doc => 'Specifies whether links to the current page should be used')


########################################################################
# Everything related to the content processor extension
require 'webgen/content_processor'

website.ext.content_processor = content_processor = Webgen::ContentProcessor.new
content_processor.register('Blocks', :author => author,
                           :summary => 'Replaces a special xml tag with the rendered block of a path in Webgen Page Format')
content_processor.register('Builder', :author => author,
                           :summary => 'Allows one to programatically create valid XHTML/XML documents')
content_processor.register('Erb', :author => author,
                           :summary => 'Allows one to use ERB (embedded Ruby) in the content')

content_processor.register('Erubis', :author => author,
                           :summary => 'Allows one to use ERB (embedded Ruby) in the content (faster than the erb processor')
option('content_processor.erubis.use_pi', false,
       'Specifies whether processing instructions should be used', &true_or_false)
option('content_processor.erubis.options', {},
       'A hash of additional, erubis specific options')

content_processor.register('Fragments', :author => author,
                            :summary => 'Generates fragment nodes from all HTML headers which have an id attribute set')
content_processor.register('Haml', :author => author,
                           :summary => 'Allows one to write HTML with the Haml markup language')
content_processor.register('Head', :author => author,
                           :summary => 'Inserts various HTML tags like links to CSS/Javascript files into the HTML head tag')

content_processor.register('Kramdown', :author => author,
                           :summary => 'Fast superset of Markdown to HTML converter')
option('content_processor.kramdown.options', {:auto_ids => true},
       'The options hash for the kramdown processor')
option('content_processor.kramdown.handle_links', true,
       'Whether all links in a kramdown document should be processed by webgen', &true_or_false)

content_processor.register('Maruku', :author => author,
                           :summary => 'Converts content written in a superset of Markdown to HTML')
content_processor.register('RDiscount', :author => author,
                           :summary => 'Converts content written in Markdown to HTML')
content_processor.register('RDoc', :author => author,
                           :summary => 'Converts content written in RDoc markup to HTML')

content_processor.register('RedCloth', :author => author,
                           :summary => 'Converts content written in Textile markup to HTML')
option('content_processor.redcloth.hard_breaks', false,
       'Specifies whether new lines are turned into hard breaks', &true_or_false)

content_processor.register('Sass', :author => author,
                           :summary => 'Converts content written in the Sass meta language to valid CSS')
content_processor.register('Scss', :author => author,
                           :summary => 'Converts content written in the Sassy CSS language to valid CSS')
content_processor.register('Tags', :author => author,
                           :summary => 'Provides a very easy way for adding dynamic content')

content_processor.register('Tidy', :author => author,
                           :summary => 'Uses the tidy program to convert the content into valid (X)HTML')
option('content_processor.tidy.options', "-raw",
       "Additional options passed to the tidy command (-q and -f are always used)", &is_string)

content_processor.register('Xmllint', :author => author,
                           :summary => 'Uses the xmllint program to check the content for well-formedness and/or validness')
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
destination.register("FileSystem", :author => author,
                     :summary => 'Writes the generated content to a specified directory')

# TODO: Do we really need this option?
#config.output.do_deletion(false, :doc => 'Specifies whether the generated output paths should be deleted once the sources are deleted')


########################################################################
# Everything related to the item tracker extension
require 'webgen/item_tracker'

website.ext.item_tracker = item_tracker = Webgen::ItemTracker.new(website)
item_tracker.register('NodeContent', :author => author,
                      :summary => 'Tracks changes to the content of a node')

item_tracker.register('NodeMetaInfo', :author => author,
                      :summary => 'Tracks changes to the meta information of a node')
website.blackboard.add_listener(:after_node_created) do |node|
  item_tracker.add(node, :node_meta_info, node.alcn)
end


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
           'blocks' => {'default' => {'pipeline' => 'erb,tags,blocks,head'}}
         },
         'page' => {
           'blocks' => {'default' => {'pipeline' => 'erb,tags,kramdown,blocks,fragments'}}
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

path_handler.register('Directory', :patterns => ['**/'], :author => author,
                      :summary => 'Creates the needed output directories from the source directories')
path_handler.register('Metainfo', :patterns => ['**/metainfo', '**/*.metainfo'], :author => author,
                      :summary => 'Provides the ability to set meta information for any path')

path_handler.register('Template', :patterns => ['**/*.template'], :author => author,
                      :summary => 'Handles template files for layouting page and other template files')
option('path_handler.template.default_template', 'default.template',
       'The name of the default template file')

path_handler.register('Page', :patterns => ['**/*.page'], :author => author,
                      :summary => 'Generates HTML files from page files')

path_handler.register('Copy', :author => author,
                      :summary => 'Copies files from the source to the destination directory, optionally processing them with one or more content processors')
option('path_handler.copy.patterns',
       ['**/*.css', '**/*.js', '**/*.html', '**/*.gif', '**/*.jpg', '**/*.png', '**/*.ico'],
       'The path patterns for the paths that should just be copied to the destination') do |val|
  raise "The value has to be an array of path patterns (strings)" unless val.kind_of?(Array) && val.all? {|i| i.kind_of?(String)}
  val
end

path_handler.register('Feed', :patterns => ['**/*.feed'], :author => author,
                      :summary => 'Automatically generates atom or RSS feeds for a set of files')
path_handler.register('Sitemap', :patterns => ['**/*.sitemap'], :author => author,
                      :summary => 'Generates a sitemap file')
path_handler.register('Virtual', :patterns => ['**/virtual', '**/*.virtual'], :author => author,
                      :summary => 'Creates nodes from virtual paths')


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
option('sources.passive', [], # [['/', :resource, "webgen-passive-sources"]],
       'One or more sources from which paths are read that are only used when referenced ', &sources_validator)
option('sources.ignore_paths', ['**/*~', '**/.svn/**'],
       'Patterns for paths that should be ignored') do |val|
  raise "The value has to be an array of patterns" unless val.kind_of?(Array) && val.all? {|item| item.kind_of?(String)}
  val
end

website.ext.source = source = Webgen::Source.new(website)
source.register("FileSystem", :author => author,
                :summary => 'Provides paths under a specified directory that match a certain pattern')
source.register("Resource", :author => author,
                :summary => 'Provides paths from the specified resource')
source.register("Stacked", :author => author,
                :summary => 'Allows combining multiple sources into one')
source.register("TarArchive", :author => author,
                :summary => 'Provides paths from a specified (gzipped) tar archive that match a certain pattern')


########################################################################
# Everything related to the tag extension
require 'webgen/tag'

website.ext.tag = tag = Webgen::Tag.new(website)

option('tag.prefix', '',
       'The prefix used for tag names to avoid name clashes when another content processor uses similar markup.',
       &is_string)

#TODO: add options and summary information for all tags

tag.register('Relocatable', :names => ['relocatable', 'r'], :author => author,
             :summary => '')
tag.register('Metainfo', :names => :default, :author => author,
             :summary => '')
tag.register('Menu', :author => author,
             :summary => '')
tag.register('BreadcrumbTrail', :author => author,
             :summary => '')
tag.register('Langbar', :author => author,
             :summary => '')
tag.register('IncludeFile', :author => author,
             :summary => '')
tag.register('ExecuteCommand', :names => 'execute_cmd', :author => author,
             :summary => '')
tag.register('Coderay', :author => author,
             :summary => '')
tag.register('Date', :author => author,
             :summary => '')
tag.register('Sitemap', :author => author,
             :summary => '')
tag.register('TikZ', :author => author,
             :summary => '')
tag.register('Link', :author => author,
             :summary => '')
