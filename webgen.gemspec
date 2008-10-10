--- !ruby/object:Gem::Specification 
name: webgen
version: !ruby/object:Gem::Version 
  version: 0.5.5.20081010
platform: ruby
authors: 
- Thomas Leitner
autorequire: 
bindir: bin
cert_chain: []

date: 2008-10-10 00:00:00 +02:00
default_executable: webgen
dependencies: 
- !ruby/object:Gem::Dependency 
  name: cmdparse
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 2.0.2
    version: 
- !ruby/object:Gem::Dependency 
  name: maruku
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.5.9
    version: 
- !ruby/object:Gem::Dependency 
  name: facets
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 2.4.3
    version: 
- !ruby/object:Gem::Dependency 
  name: rake
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.8.3
    version: 
- !ruby/object:Gem::Dependency 
  name: ramaze
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: "2008.06"
    version: 
- !ruby/object:Gem::Dependency 
  name: launchy
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.3.2
    version: 
- !ruby/object:Gem::Dependency 
  name: rcov
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.8.1.2.0
    version: 
- !ruby/object:Gem::Dependency 
  name: dcov
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.2.2
    version: 
- !ruby/object:Gem::Dependency 
  name: rubyforge
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 1.0.0
    version: 
- !ruby/object:Gem::Dependency 
  name: RedCloth
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 3.0.0
    version: 
- !ruby/object:Gem::Dependency 
  name: haml
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 2.0.1
    version: 
- !ruby/object:Gem::Dependency 
  name: builder
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 2.1.2
    version: 
- !ruby/object:Gem::Dependency 
  name: rdoc
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 2.0.0
    version: 
- !ruby/object:Gem::Dependency 
  name: coderay
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.7.4.215
    version: 
- !ruby/object:Gem::Dependency 
  name: feedtools
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.2.29
    version: 
- !ruby/object:Gem::Dependency 
  name: erubis
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 2.6.2
    version: 
- !ruby/object:Gem::Dependency 
  name: rdiscount
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 1.2.9
    version: 
description: webgen is used to generate static websites from templates and content files (which can be written in a markup language). It can generate dynamic content like menus on the fly and comes with many powerful extensions.
email: t_leitner@gmx.at
executables: 
- webgen
extensions: []

extra_rdoc_files: []

files: 
- Rakefile
- setup.rb
- AUTHORS
- THANKS
- COPYING
- GPL
- bin/webgen
- data/webgen
- data/webgen/resources.yaml
- data/webgen/webgui
- data/webgen/webgui/controller
- data/webgen/webgui/controller/main.rb
- data/webgen/webgui/overrides
- data/webgen/webgui/overrides/win32console.rb
- data/webgen/webgui/public
- data/webgen/webgui/public/css
- data/webgen/webgui/public/css/jquery.autocomplete.css
- data/webgen/webgui/public/css/ramaze_error.css
- data/webgen/webgui/public/css/style.css
- data/webgen/webgui/public/img
- data/webgen/webgui/public/img/headerbg.jpg
- data/webgen/webgui/public/img/webgen_logo.png
- data/webgen/webgui/public/js
- data/webgen/webgui/public/js/jquery.autocomplete.js
- data/webgen/webgui/public/js/jquery.js
- data/webgen/webgui/view
- data/webgen/webgui/view/create_website.xhtml
- data/webgen/webgui/view/error.xhtml
- data/webgen/webgui/view/index.xhtml
- data/webgen/webgui/view/manage_website.xhtml
- data/webgen/webgui/view/page.xhtml
- data/webgen/website_skeleton
- data/webgen/website_skeleton/config.yaml
- data/webgen/website_skeleton/ext
- data/webgen/website_skeleton/ext/init.rb
- data/webgen/website_skeleton/Rakefile
- data/webgen/website_skeleton/README
- data/webgen/website_skeleton/src
- data/webgen/website_styles
- data/webgen/website_styles/1024px
- data/webgen/website_styles/1024px/README
- data/webgen/website_styles/1024px/src
- data/webgen/website_styles/1024px/src/default.css
- data/webgen/website_styles/1024px/src/default.template
- data/webgen/website_styles/1024px/src/images
- data/webgen/website_styles/1024px/src/images/background.gif
- data/webgen/website_styles/andreas00
- data/webgen/website_styles/andreas00/README
- data/webgen/website_styles/andreas00/src
- data/webgen/website_styles/andreas00/src/default.css
- data/webgen/website_styles/andreas00/src/default.template
- data/webgen/website_styles/andreas00/src/images
- data/webgen/website_styles/andreas00/src/images/bg.gif
- data/webgen/website_styles/andreas00/src/images/front.jpg
- data/webgen/website_styles/andreas00/src/images/menubg.gif
- data/webgen/website_styles/andreas00/src/images/menubg2.gif
- data/webgen/website_styles/andreas01
- data/webgen/website_styles/andreas01/README
- data/webgen/website_styles/andreas01/src
- data/webgen/website_styles/andreas01/src/default.css
- data/webgen/website_styles/andreas01/src/default.template
- data/webgen/website_styles/andreas01/src/images
- data/webgen/website_styles/andreas01/src/images/bg.gif
- data/webgen/website_styles/andreas01/src/images/front.jpg
- data/webgen/website_styles/andreas01/src/print.css
- data/webgen/website_styles/andreas03
- data/webgen/website_styles/andreas03/README
- data/webgen/website_styles/andreas03/src
- data/webgen/website_styles/andreas03/src/default.css
- data/webgen/website_styles/andreas03/src/default.template
- data/webgen/website_styles/andreas03/src/images
- data/webgen/website_styles/andreas03/src/images/bodybg.png
- data/webgen/website_styles/andreas03/src/images/contbg.png
- data/webgen/website_styles/andreas03/src/images/footerbg.png
- data/webgen/website_styles/andreas03/src/images/gradient1.png
- data/webgen/website_styles/andreas03/src/images/gradient2.png
- data/webgen/website_styles/andreas04
- data/webgen/website_styles/andreas04/README
- data/webgen/website_styles/andreas04/src
- data/webgen/website_styles/andreas04/src/default.css
- data/webgen/website_styles/andreas04/src/default.template
- data/webgen/website_styles/andreas04/src/images
- data/webgen/website_styles/andreas04/src/images/blinkarrow.gif
- data/webgen/website_styles/andreas04/src/images/bodybg.png
- data/webgen/website_styles/andreas04/src/images/contentbg.png
- data/webgen/website_styles/andreas04/src/images/entrybg.png
- data/webgen/website_styles/andreas04/src/images/flash.gif
- data/webgen/website_styles/andreas04/src/images/flash2.gif
- data/webgen/website_styles/andreas04/src/images/globe.gif
- data/webgen/website_styles/andreas04/src/images/globebottom.gif
- data/webgen/website_styles/andreas04/src/images/linkarrow.gif
- data/webgen/website_styles/andreas04/src/images/menuhover.png
- data/webgen/website_styles/andreas05
- data/webgen/website_styles/andreas05/README
- data/webgen/website_styles/andreas05/src
- data/webgen/website_styles/andreas05/src/default.css
- data/webgen/website_styles/andreas05/src/default.template
- data/webgen/website_styles/andreas05/src/images
- data/webgen/website_styles/andreas05/src/images/bodybg.gif
- data/webgen/website_styles/andreas05/src/images/front.png
- data/webgen/website_styles/andreas06
- data/webgen/website_styles/andreas06/README
- data/webgen/website_styles/andreas06/src
- data/webgen/website_styles/andreas06/src/default.css
- data/webgen/website_styles/andreas06/src/default.template
- data/webgen/website_styles/andreas06/src/images
- data/webgen/website_styles/andreas06/src/images/bodybg.gif
- data/webgen/website_styles/andreas06/src/images/boxbg.gif
- data/webgen/website_styles/andreas06/src/images/greypx.gif
- data/webgen/website_styles/andreas06/src/images/header.jpg
- data/webgen/website_styles/andreas06/src/images/innerbg.gif
- data/webgen/website_styles/andreas06/src/images/leaves.jpg
- data/webgen/website_styles/andreas06/src/images/tabs.gif
- data/webgen/website_styles/andreas07
- data/webgen/website_styles/andreas07/README
- data/webgen/website_styles/andreas07/src
- data/webgen/website_styles/andreas07/src/browserfix.css
- data/webgen/website_styles/andreas07/src/default.css
- data/webgen/website_styles/andreas07/src/default.template
- data/webgen/website_styles/andreas07/src/images
- data/webgen/website_styles/andreas07/src/images/bodybg.gif
- data/webgen/website_styles/andreas07/src/images/sidebarbg.gif
- data/webgen/website_styles/andreas08
- data/webgen/website_styles/andreas08/README
- data/webgen/website_styles/andreas08/src
- data/webgen/website_styles/andreas08/src/default.css
- data/webgen/website_styles/andreas08/src/default.template
- data/webgen/website_styles/andreas09
- data/webgen/website_styles/andreas09/README
- data/webgen/website_styles/andreas09/src
- data/webgen/website_styles/andreas09/src/default.css
- data/webgen/website_styles/andreas09/src/default.template
- data/webgen/website_styles/andreas09/src/images
- data/webgen/website_styles/andreas09/src/images/bodybg-black.jpg
- data/webgen/website_styles/andreas09/src/images/bodybg-green.jpg
- data/webgen/website_styles/andreas09/src/images/bodybg-orange.jpg
- data/webgen/website_styles/andreas09/src/images/bodybg-purple.jpg
- data/webgen/website_styles/andreas09/src/images/bodybg-red.jpg
- data/webgen/website_styles/andreas09/src/images/bodybg.jpg
- data/webgen/website_styles/andreas09/src/images/footerbg.jpg
- data/webgen/website_styles/andreas09/src/images/menuhover-black.jpg
- data/webgen/website_styles/andreas09/src/images/menuhover-green.jpg
- data/webgen/website_styles/andreas09/src/images/menuhover-orange.jpg
- data/webgen/website_styles/andreas09/src/images/menuhover-purple.jpg
- data/webgen/website_styles/andreas09/src/images/menuhover-red.jpg
- data/webgen/website_styles/andreas09/src/images/menuhover.jpg
- data/webgen/website_styles/simple
- data/webgen/website_styles/simple/README
- data/webgen/website_styles/simple/src
- data/webgen/website_styles/simple/src/default.css
- data/webgen/website_styles/simple/src/default.template
- data/webgen/website_templates
- data/webgen/website_templates/default
- data/webgen/website_templates/default/README
- data/webgen/website_templates/default/src
- data/webgen/website_templates/default/src/index.page
- data/webgen/website_templates/project
- data/webgen/website_templates/project/README
- data/webgen/website_templates/project/src
- data/webgen/website_templates/project/src/about.page
- data/webgen/website_templates/project/src/download.page
- data/webgen/website_templates/project/src/features.page
- data/webgen/website_templates/project/src/index.page
- data/webgen/website_templates/project/src/screenshots.page
- doc/contentprocessor
- doc/contentprocessor/blocks.page
- doc/contentprocessor/builder.page
- doc/contentprocessor/erb.page
- doc/contentprocessor/erubis.page
- doc/contentprocessor/haml.page
- doc/contentprocessor/maruku.page
- doc/contentprocessor/rdiscount.page
- doc/contentprocessor/rdoc.page
- doc/contentprocessor/redcloth.page
- doc/contentprocessor/sass.page
- doc/contentprocessor/tags.page
- doc/contentprocessor.template
- doc/extensions.metainfo
- doc/extensions.page
- doc/extensions.template
- doc/faq.page
- doc/getting_started.page
- doc/index.page
- doc/manual.page
- doc/reference_configuration.page
- doc/reference_metainfo.page
- doc/sourcehandler
- doc/sourcehandler/copy.page
- doc/sourcehandler/directory.page
- doc/sourcehandler/feed.page
- doc/sourcehandler/metainfo.page
- doc/sourcehandler/page.page
- doc/sourcehandler/sitemap.page
- doc/sourcehandler/template.page
- doc/sourcehandler/virtual.page
- doc/sourcehandler.template
- doc/tag
- doc/tag/breadcrumbtrail.page
- doc/tag/coderay.page
- doc/tag/date.page
- doc/tag/executecommand.page
- doc/tag/includefile.page
- doc/tag/langbar.page
- doc/tag/menu.page
- doc/tag/metainfo.page
- doc/tag/relocatable.page
- doc/tag/sitemap.page
- doc/tag/tikz.page
- doc/tag.template
- doc/upgrading.page
- doc/webgen_page_format.page
- lib/webgen/blackboard.rb
- lib/webgen/cache.rb
- lib/webgen/cli/create_command.rb
- lib/webgen/cli/run_command.rb
- lib/webgen/cli/utils.rb
- lib/webgen/cli/webgui_command.rb
- lib/webgen/cli.rb
- lib/webgen/common/sitemap.rb
- lib/webgen/common.rb
- lib/webgen/configuration.rb
- lib/webgen/contentprocessor/blocks.rb
- lib/webgen/contentprocessor/builder.rb
- lib/webgen/contentprocessor/context.rb
- lib/webgen/contentprocessor/erb.rb
- lib/webgen/contentprocessor/erubis.rb
- lib/webgen/contentprocessor/haml.rb
- lib/webgen/contentprocessor/maruku.rb
- lib/webgen/contentprocessor/rdiscount.rb
- lib/webgen/contentprocessor/rdoc.rb
- lib/webgen/contentprocessor/redcloth.rb
- lib/webgen/contentprocessor/sass.rb
- lib/webgen/contentprocessor/tags.rb
- lib/webgen/contentprocessor.rb
- lib/webgen/coreext.rb
- lib/webgen/default_config.rb
- lib/webgen/languages.rb
- lib/webgen/loggable.rb
- lib/webgen/logger.rb
- lib/webgen/node.rb
- lib/webgen/output/filesystem.rb
- lib/webgen/output.rb
- lib/webgen/page.rb
- lib/webgen/path.rb
- lib/webgen/source/filesystem.rb
- lib/webgen/source/resource.rb
- lib/webgen/source/stacked.rb
- lib/webgen/source.rb
- lib/webgen/sourcehandler/base.rb
- lib/webgen/sourcehandler/copy.rb
- lib/webgen/sourcehandler/directory.rb
- lib/webgen/sourcehandler/feed.rb
- lib/webgen/sourcehandler/fragment.rb
- lib/webgen/sourcehandler/memory.rb
- lib/webgen/sourcehandler/metainfo.rb
- lib/webgen/sourcehandler/page.rb
- lib/webgen/sourcehandler/sitemap.rb
- lib/webgen/sourcehandler/template.rb
- lib/webgen/sourcehandler/virtual.rb
- lib/webgen/sourcehandler.rb
- lib/webgen/tag/base.rb
- lib/webgen/tag/breadcrumbtrail.rb
- lib/webgen/tag/coderay.rb
- lib/webgen/tag/date.rb
- lib/webgen/tag/executecommand.rb
- lib/webgen/tag/includefile.rb
- lib/webgen/tag/langbar.rb
- lib/webgen/tag/menu.rb
- lib/webgen/tag/metainfo.rb
- lib/webgen/tag/relocatable.rb
- lib/webgen/tag/sitemap.rb
- lib/webgen/tag/tikz.rb
- lib/webgen/tag.rb
- lib/webgen/tree.rb
- lib/webgen/version.rb
- lib/webgen/webgentask.rb
- lib/webgen/website.rb
- lib/webgen/websiteaccess.rb
- lib/webgen/websitemanager.rb
- man/man1/webgen.1
- misc/default.css
- misc/default.template
- misc/htmldoc.metainfo
- misc/htmldoc.virtual
- misc/images
- misc/images/arrow.gif
- misc/images/error.gif
- misc/images/exclamation.gif
- misc/images/headerbg.jpg
- misc/images/information.gif
- misc/images/quote.gif
- test/test_blackboard.rb
- test/test_cache.rb
- test/test_common_sitemap.rb
- test/test_configuration.rb
- test/test_contentprocessor.rb
- test/test_contentprocessor_blocks.rb
- test/test_contentprocessor_builder.rb
- test/test_contentprocessor_context.rb
- test/test_contentprocessor_erb.rb
- test/test_contentprocessor_erubis.rb
- test/test_contentprocessor_haml.rb
- test/test_contentprocessor_maruku.rb
- test/test_contentprocessor_rdiscount.rb
- test/test_contentprocessor_rdoc.rb
- test/test_contentprocessor_redcloth.rb
- test/test_contentprocessor_sass.rb
- test/test_contentprocessor_tags.rb
- test/test_languages.rb
- test/test_loggable.rb
- test/test_logger.rb
- test/test_node.rb
- test/test_output_filesystem.rb
- test/test_page.rb
- test/test_path.rb
- test/test_source_filesystem.rb
- test/test_source_resource.rb
- test/test_source_stacked.rb
- test/test_sourcehandler_base.rb
- test/test_sourcehandler_copy.rb
- test/test_sourcehandler_directory.rb
- test/test_sourcehandler_feed.rb
- test/test_sourcehandler_fragment.rb
- test/test_sourcehandler_memory.rb
- test/test_sourcehandler_metainfo.rb
- test/test_sourcehandler_page.rb
- test/test_sourcehandler_sitemap.rb
- test/test_sourcehandler_template.rb
- test/test_sourcehandler_virtual.rb
- test/test_tag_base.rb
- test/test_tag_breadcrumbtrail.rb
- test/test_tag_coderay.rb
- test/test_tag_date.rb
- test/test_tag_executecommand.rb
- test/test_tag_includefile.rb
- test/test_tag_langbar.rb
- test/test_tag_menu.rb
- test/test_tag_metainfo.rb
- test/test_tag_relocatable.rb
- test/test_tag_sitemap.rb
- test/test_tag_tikz.rb
- test/test_tree.rb
- test/test_webgentask.rb
- test/test_website.rb
- test/test_websiteaccess.rb
- test/test_websitemanager.rb
- test/helper.rb
has_rdoc: true
homepage: http://webgen.rubyforge.org
post_install_message: |+
  
  
  
  WARNING: This is an unsupported BETA version of webgen which may
  still contain bugs!
  
  The official version is called 'webgen' and can be installed via
  
      gem install webgen
  
  
  
rdoc_options: 
- --line-numbers
- --inline-source
- --promiscuous
- --main
- Webgen
require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
requirements: []

rubyforge_project: webgen
rubygems_version: 1.3.0
signing_key: 
specification_version: 2
summary: webgen beta build, not supported!!!
test_files: []

