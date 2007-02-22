# -*- ruby -*-
#
# $Id$
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#


begin
  require 'rubygems'
  require 'rake/gempackagetask'
rescue Exception
end

require 'fileutils'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'rake/testtask'

# General things  ##############################################################

$:.push File.expand_path( File.join( File.dirname(__FILE__), 'lib' ) )
require 'webgen/config'
require 'webgen/rake/webgentask'

PKG_NAME = "webgen"
PKG_VERSION = Webgen::VERSION.join( '.' )
PKG_FULLNAME = PKG_NAME + "-" + PKG_VERSION
PKG_SUMMARY = Webgen::SUMMARY
PKG_DESCRIPTION = Webgen::DESCRIPTION

SRC_RB = FileList['lib/**/*.rb']


# The default task is run if rake is given no explicit arguments.
desc "Default Task"
task :default => :test


# End user tasks ################################################################

desc "Prepares for installation"
task :prepare do
  ruby "setup.rb config"
  ruby "setup.rb setup"
end


desc "Installs the package #{PKG_NAME}"
task :install => [:prepare] do
  ruby "setup.rb install"
end


CLEAN.exclude( 'doc/src/documentation/plugins/core' )
CLEAN.exclude( 'doc/output/documentation/plugins/core' )
task :clean do
  ruby "setup.rb clean"
end


desc "Creates the whole documentation"
task :doc => [:rdoc, :webgen]

Webgen::Rake::WebgenTask.new do |webgen|
  webgen.directory = File.join( File.dirname( __FILE__ ), 'doc' )
  webgen.clobber_outdir = true
end
task :webgen => [:create_examples]

rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/output/rdoc'
  rdoc.title    = PKG_NAME
  rdoc.options << '--line-numbers' << '--inline-source' << '-m README'
  rdoc.rdoc_files.include( 'README' )
  rdoc.rdoc_files.include( 'lib/**/*.rb' )
end


CLOBBER << "doc/examples"
CLOBBER << "doc/src/examples/website_templates"
CLOBBER << "doc/src/examples/website_styles"
CLOBBER << "doc/src/examples/gallery_styles"
CLOBBER << "doc/src/examples/sipttra_styles"
CLOBBER << "doc/plugin/gallery"
desc "Creates the files for the examples section of the docu"
task :create_examples do
  require 'webgen/website'

  # website templates
  data = {}
  data[:dirname] = 'Website Templates'
  data[:desc]= "h2. List of website templates

The website templates open in an iframe when you use the menu items. Use the links provided below to
open the website templates directly (fullscreen).

Following is the list of all available website templates:
"
  data[:entries] = Webgen::WebSiteTemplate.entries
  create_examples( 'website_templates', data, nil, 'default' )

  # website styles
  data = {}
  data[:dirname] = 'Website Styles'
  data[:desc]= "h2. List of website styles

The website styles open in an iframe when you use the menu items. Use the links provided below to
open the website styles directly (fullscreen).

Following is the list of all available website styles:
"
  data[:entries] = Webgen::WebSiteStyle.entries
  create_examples( 'website_styles', data, 'project', nil )

  # gallery styles
  Webgen::GalleryStyle.entries.each do |name, entry|
    base_dir = "doc/src/examples/gallery_styles/#{name}"
    files_mtime = (entry.files + entry.plugin_files).collect {|f| File.mtime( f) }.max
    dir_mtime = File.mtime( base_dir ) rescue Time.parse("1970-1-1")
    if dir_mtime < files_mtime
      puts "Creating example files for gallery style '#{name}'..."
      mkdir_p( "doc/plugin/gallery/#{name}" )
      FileUtils.cp( entry.plugin_files, "doc/plugin/gallery/#{name}" )
      mkdir_p( base_dir )
      FileUtils.touch( base_dir )
      entry.copy_to( base_dir )

      additional = case name
                   when 'slides' then "layouter: slides\nthumbnailResizeMethod: :cropped"
                   else ''
                   end
      File.open( File.join( base_dir, "#{name}.gallery" ), 'w+' ) do |f|
        f.write("title: index
images: ../../images/*
imagesPerPage: 8
mainPageMetaInfo:
  inMenu: true
#{additional}
---
../../images/image01.jpg:
  title: Chinese Garden
  description: This picture show the Chinese Garden located in the outskirts of Vienna (Austria).

../../images/image02.jpg:
  title: Goldenes Dach
  description: This is the landmark of Innsbruck (Tyrol, Austria), called the 'Goldene Dach' (golden roof).

../../images/image03.jpg:
  title: Mountains in Innsbruck
  description: A view from the <a href='http://www.nordpark.com'>NordPark</a> in Innsbruck.

../../images/image04.jpg:
  title: Kristallwelten 1
  description: The entry to the 'Kristallwelten' of <a href='http://www.swarovski.com'>Swarovski</a> in Innsbruck.

../../images/image05.jpg:
  title: Kristallwelten 2
  description: On the roof of the building.

../../images/image06.jpg:
  title: Kristallwelten 3
  description: Some crystals.

../../images/image07.jpg:
  title: Minimundus 1
  description: A french castle

../../images/image08.jpg:
  title: Minimundus 2
  description: A small copy of the <a href=''>Sagrada Familia</a> of Barcelona.

../../images/image09.jpg:
  title: Minimundus 3
  description: The Stephansdom in Vienna.

../../images/image10.jpg:
  title: Minimundus 4
  description: Overview of Minimundus, a place with smaller versions of famous buildings.

../../images/image11.jpg:
  title: Velden
  description: Photo from Velden, Wörtersee, Carinthia, Austria

../../images/image12.jpg:
  title: Stockholm 1
  description: A 300-year-old ship, the Wasa, located in the Wasamuseet in Stockholm.

../../images/image13.jpg:
  title: Stockholm 2
  description: A fort near Stockholm.

../../images/image14.jpg:
  title: Stockholm 3
  description: Overview of Gamla Stan (old town centre of Stockholm)

../../images/image15.jpg:
  title: Stockholm 4
  description: View from a bridge in the direction of Gamla Stan

../../images/image16.jpg:
  title: Zakynthos 1
  description: An isle that looks like a turtle

../../images/image17.jpg:
  title: Zakynthos 2
  description: The oldest olive tree of Zakynthos.

../../images/image18.jpg:
  title: Zakynthos 3
  description: The Navagio ship wreck, very famous Greek tourist destination.
")
      end
    end
  end

  data = {}
  data[:dirname] = 'Gallery Styles'
  data[:desc]= "h2. List of gallery styles

The gallery style example pages open in an iframe when you use the menu items. Use the links
provided below to open the gallery style example pages directly (fullscreen).

Following is the list of all available gallery styles:
"
  data[:entries] = Webgen::GalleryStyle.entries
  create_example_index( "doc/src/examples/gallery_styles/index.page", data )


  # sipttra styles
  Webgen::SipttraStyle.entries.each do |name, entry|
    base_dir = "doc/src/examples/sipttra_styles/#{name}"
    files_mtime = entry.files.collect {|f| File.mtime( f ) }.max
    dir_mtime = File.mtime( base_dir ) rescue Time.parse("1970-1-1")
    if dir_mtime < files_mtime
      puts "Creating example files for sipttra style '#{name}'..."
      mkdir_p( base_dir )
      FileUtils.touch( base_dir )
      entry.copy_to( base_dir )

      File.open( File.join( base_dir, "index.todo" ), 'w+' ) do |f|
        f.write("---
webgen-metainfo:
  template: sipttra.template
---
###### Milestones ######
* Feb07 (2007-02-28) Bug fixes and small enhancements
  - include patches/requests created since 0.4.1 release
  - add support for sipttra files, the Simple Plain Text Tracker

* F: Ideas and todo items for future versions

  This milestone holds all ideas/todo items/requests which are implemented some
  time in the future.

###### Implementation (open) ######

* T002 [F] add localization support for all files
  See also FR#7891

* T003 [F] add additional tests for sipttra implementation

## Implementation (closed) ##

* T004 [Feb07] use HTML as default format for templates
  See also FR#7893

* T006 [Feb07] add parameter for not showing index files in breadcrumb trail
  See also PATCH#7942

* T007 [Feb07] implement a plugin for storing/accessing global variables

* T001 [Feb07] add support for sipttra files

###### Bugs (open) ######

* T013 [Feb07] fix TreeWalker (write mail to mailing list and ask what should be done with it)

## Bugs (closed) ##

* T005 [Feb07] check all styles for correctly selected menu items
  style issues because of new span element when File/DefaultHandler:linkToCurrentPage is false

* T009 [Feb07] PluginManager#init: log typo for 'creating plugin of class...'

* T012 [Feb07] update copyright notices for included website templates
  See also Bug#8725

* T008 [Feb07] PluginLoader shouldn't load plugins that are already loaded in the DEFAULT_WRAPPER_MODULE
  When site plugins use the load_plugin command to load plugins that are shipped with webgen and loaded by
  default, some plugins don't work correctly as plugin classes get defined twice with different oids.

###### Documentation (open) ######

* T011 [Feb07] add example section for sipttra style files

## Documentation (closed) ##

* T010 [Feb07] add some example sites
  It was requested that one should be able to download some zipped examples sites from the examples
  section showing basic use cases for webgen.
")
      end
      File.open( File.join( base_dir, "default.template" ), 'w+' ) do |f|
        f.write( '---
template: ~
---
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="{lang:}">
  <head>
    <title>Sipttra Style</title>
    <link rel="stylesheet" href="{resource: {name: webgen-css, insert: :path}}" type="text/css" media="screen" />
    <link rel="stylesheet" href="{relocatable: css/sipttra.css}" type="text/css" media="screen" />
    <script type="text/javascript" src="{relocatable: js/sipttra.js}" />
  </head>
  <body>
    {block:}
  </body>
</html>
')
      end
      File.open( File.join( File.dirname( base_dir ), "#{name}.page" ), 'w+' ) do |f|
        f.write("---
title: #{name}
inMenu: true
--- content, html
<object type='text/html' data='#{name}/index.html' width='100%' height='600px' />
")
      end
    end
  end

  data = {}
  data[:dirname] = 'Sipttra Styles'
  data[:desc]= "h2. List of sipttra styles

The sipttra style example pages open in an iframe when you use the menu items. Use the links
provided below to open the sipttra style example pages directly (fullscreen). All sipttra style
examples use

Following is the list of all available sipttra styles:
"
  data[:entries] = Webgen::SipttraStyle.entries
  create_example_index( "doc/src/examples/sipttra_styles/index.page", data )

end


task :test do
  ruby "-Ilib -Itest test/runtests.rb"
end

# Developer tasks ##############################################################


PKG_FILES = FileList.new( [
                            'setup.rb',
                            'TODO',
                            'COPYING',
                            'README',
                            'Rakefile',
                            'ChangeLog',
                            'VERSION',
                            'bin/webgen',
                            'lib/**/*.rb',
                            'data/**/*',
                            'testsite/**/*',
                            'test/**/*',
                            'doc/**/*'
                          ]) do |fl|
  fl.exclude( /\bsvn\b/ )
  fl.exclude( 'testsite/output' )
  fl.exclude( 'testsite/coverage' )
  fl.exclude( 'doc/output' )
end

CLOBBER << "otherdata/web-for-gallery-pics/output"
task :create_gal_layout_pics do
  chdir 'otherdata/web-for-gallery-pics' do
    ruby "-I../../lib create_pictures.rb"
  end
end

CLOBBER << "ChangeLog"
task :gen_changelog do
  sh "svn log -r HEAD:1 -v > ChangeLog"
end

CLOBBER << "VERSION"
task :gen_version do
  puts "Generating VERSION file"
  File.open( 'VERSION', 'w+' ) do |file| file.write( PKG_VERSION + "\n" ) end
end

task :package => [:gen_changelog, :gen_version]

Rake::PackageTask.new( PKG_NAME, PKG_VERSION ) do |p|
  p.need_tar = true
  p.need_zip = true
  p.package_files = PKG_FILES
end

if !defined? Gem
  puts "Package Target requires RubyGEMs"
else
  spec = Gem::Specification.new do |s|

    #### Basic information

    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.summary = PKG_SUMMARY
    s.description = PKG_DESCRIPTION

    #### Dependencies, requirements and files

    s.files = PKG_FILES.to_a
    s.add_dependency( 'cmdparse', '~> 2.0.0' )

    s.require_path = 'lib'
    s.autorequire = nil

    s.executables = ['webgen']
    s.default_executable = 'webgen'

    #### Documentation

    s.has_rdoc = true
    s.extra_rdoc_files = rd.rdoc_files.reject do |fn| fn =~ /\.rb$/ end.to_a
    s.rdoc_options = ['--line-numbers', '-m', 'README']

    #### Author and project details

    s.author = "Thomas Leitner"
    s.email = "t_leitner@gmx.at"
    s.homepage = "http://webgen.rubyforge.org"
    s.rubyforge_project = "webgen"
  end

  Rake::GemPackageTask.new( spec ) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

end

desc "Upload documentation to homepage"
task :uploaddoc => [:doc] do
  Dir.chdir('doc/output')
  sh "scp -r * gettalong@rubyforge.org:/var/www/gforge-projects/#{PKG_NAME}/"
end


# Helper methods ###################################################################

def create_examples( dir_name, data, template = nil, style = nil )
  base_dir = 'doc/examples'
  src_dir = 'doc/src/examples'

  mkdir_p( File.join( src_dir, dir_name ) )
  mkdir_p( File.join( base_dir, dir_name ) )
  data[:entries].sort.each do |name, entry|
    dir = File.join( base_dir, dir_name, name )
    files_mtime = entry.files.collect {|f| File.mtime( f ) }.max
    dir_mtime = File.mtime( dir ) rescue Time.parse("1970-1-1")
    if dir_mtime < files_mtime
      puts "Creating example files for #{dir_name} '#{name}'..."
      rm_rf( dir )
      Webgen::WebSite.create_website( dir, template || name, style || name )
      File.open( File.join( dir, 'config.yaml' ), 'w+' ) do |f|
        f.write( "Core/Configuration: \n"+
                 "  outDir: ../../../output/examples/#{dir_name}/#{name}" )
      end
      Webgen::WebSite.new( dir ).render
    end
    File.open( File.join( src_dir, dir_name, "#{name}.page" ), 'w+' ) do |f|
      f.write("---
title: #{name}
inMenu: true
--- content, html
<object type='text/html' data='#{name}/index.html' width='100%' height='600px' />
")
    end
  end
  create_example_index( File.join( src_dir, dir_name, "index.page" ), data )
end

def create_example_index( filename, data )
  mkdir_p(  File.dirname( filename ) )
  index = File.open( File.join( filename ), 'w+' )
  index.puts("---
title: Index
directoryName: #{data[:dirname]}
---
#{data[:desc]}

")
  data[:entries].sort.each do |name, entry|
    index.puts("* <a href='#{name}/index.html'>#{name}</a>\n\n")
    entry.infos.sort.each do |info_name, info_value|
      index.puts("  * *#{info_name.capitalize}*: #{info_value}")
    end
  end
  index.close
end
