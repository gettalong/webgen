module Webgen

  # Namespace for all classes that are useable by Webgen::ContentProcessor::Tag.
  #
  # Have a look at the documentation for Webgen::Tag::Base for details on how to implement a tag
  # class.
  module Tag

    autoload :Base, 'webgen/tag/base'
    autoload :Relocatable, 'webgen/tag/relocatable'
    autoload :Metainfo, 'webgen/tag/metainfo'
    autoload :Menu, 'webgen/tag/menu'
    autoload :BreadcrumbTrail, 'webgen/tag/breadcrumbtrail'

  end

end
