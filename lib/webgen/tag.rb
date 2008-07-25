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
    autoload :Langbar, 'webgen/tag/langbar'
    autoload :IncludeFile, 'webgen/tag/includefile'
    autoload :ExecuteCommand, 'webgen/tag/executecommand'
    autoload :Coderay, 'webgen/tag/coderay'

  end

end
