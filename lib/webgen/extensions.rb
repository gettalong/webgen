# -*- encoding: utf-8 -*-
#
# This file defines the configuration options used by webgen and initializes all extensions shipped
# with webgen itself.

cfg = $website.config

####
# General configuration parameters
cfg.define_option('website.cache', [:file, 'webgen.cache'],
                  'The file name (or string) from/to which the cache is read/written') do |val|
  raise "The value has to be an array with two values" unless val.kind_of?(Array) && val.length == 2
  raise "The first value has to be :file or :string" unless val[0] == :file || val[0] == :string
  val
end

cfg.define_option('website.lang', 'en', 'The default language used for the website') do |val|
  lang = LanguageManager.language_for_code(val)
  raise "Unknown language code '#{val}'" if lang.nil?
  lang
end

#config.website.link_to_current_page(false, :doc => 'Specifies whether links to the current page should be used')


####
# Everything related to the content processor extension
require 'webgen/content_processor'

$website.ext.content_processor = content_processor = Webgen::ContentProcessor.new
content_processor.register 'Tags'
content_processor.register 'Blocks'
content_processor.register 'Maruku'
content_processor.register 'RedCloth'
content_processor.register 'Erb'
content_processor.register 'Haml'
content_processor.register 'Sass'
content_processor.register 'Scss'
content_processor.register 'RDoc'
content_processor.register 'Builder'
content_processor.register 'Erubis'
content_processor.register 'RDiscount'
content_processor.register 'Fragments'
content_processor.register 'Head'
content_processor.register 'Tidy'
content_processor.register 'Xmllint'
content_processor.register 'Kramdown'
content_processor.register 'Less'


####
# Everything related to the destination extension
require 'webgen/destination'

cfg.define_option('destination', [:file_system, 'out'],
                  'The destination extension which is used to output the generated paths.') do |val|
  raise "The value needs to be an array with at least one value (the destination extension name)" unless val.kind_of?(Array) && val.length >=1
  val
end
# Do we really need this option?
#config.output.do_deletion(false, :doc => 'Specifies whether the generated output paths should be deleted once the sources are deleted')

$website.ext.destination = destination = Webgen::Destination.new($website)
destination.register "FileSystem"


####
# Everything related to the item tracker extension
require 'webgen/item_tracker'

$website.ext.item_tracker = item_tracker = Webgen::ItemTracker.new($website)
item_tracker.register 'NodeContent'
item_tracker.register 'NodeMetaInfo'


####
# Everything related to the node finder extension
require 'webgen/node_finder'
$website.ext.node_finder = Webgen::NodeFinder.new($website)


####
# Everything related to the source extension
require 'webgen/source'

sources_validator = lambda do |val|
  raise "The value has to be an array of arrays" unless val.kind_of?(Array) && val.all? {|item| item.kind_of?(Array)}
  raise "Each sub array needs to specify at least the mount point and source extension name" unless val.all? {|item| item.length >= 2}
  val
end
cfg.define_option('sources', [['/', :file_system, 'src']],
                  'One or more sources from which paths are read', &sources_validator)
cfg.define_option('passive_sources', [['/', :resource, "webgen-passive-sources"]],
                  'One or more sources from which paths are read that are only used when referenced ', &sources_validator)

$website.ext.source = source = Webgen::Source.new($website)
source.register "Stacked"
source.register "FileSystem"
source.register "Resource"
source.register "TarArchive"


####
# Everything related to the tag extension
require 'webgen/tag'

$website.ext.tag = tag = Webgen::Tag.new
tag.register 'Relocatable', :names => ['relocatable', 'r']
tag.register 'Metainfo', :names => :default
tag.register 'Menu'
tag.register 'BreadcrumbTrail'
tag.register 'Langbar'
tag.register 'IncludeFile'
tag.register 'ExecuteCommand', :names => 'execute_cmd'
tag.register 'Coderay'
tag.register 'Date'
tag.register 'Sitemap'
tag.register 'TikZ'
tag.register 'Link'
