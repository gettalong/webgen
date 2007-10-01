# -*- ruby -*-
#
# webgen: template based static website generator
# Copyright (C) 2007 Thomas Leitner
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


# load all optional developer libraries
require 'rubygems' rescue nil
require 'rake/gempackagetask' rescue nil
require 'rubyforge' rescue nil
require 'rcov/rcovtask' rescue nil

require 'fileutils'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'rake/testtask'


# General things  ##############################################################

require './lib/webgen/config'

PKG_NAME = "webgen"
PKG_VERSION = Webgen::VERSION.join( '.' )
PKG_FULLNAME = PKG_NAME + "-" + PKG_VERSION
PKG_SUMMARY = Webgen::SUMMARY
PKG_DESCRIPTION = Webgen::DESCRIPTION
PKG_AUTHOR_NAME, PKG_AUTHOR_EMAIL = Webgen::AUTHOR.split(/\s?(?=<)/)

RF_NAME = PKG_NAME
RF_DOC_PATH = PKG_VERSION
RF_SYNC_OPTIONS="--delete" #Used --excluded when deploying into root to not delete prior docs

# The default task is run if rake is given no explicit arguments.
desc "Default Task"
task :default => :test


# End user tasks ################################################################

desc "Install #{PKG_NAME}"
task :install do
  ruby "setup.rb config"
  ruby "setup.rb setup"
  ruby "setup.rb install"
end

task :clean do
  ruby "setup.rb clean"
end


desc "Creates the whole documentation"
task :doc => [:rdoc]

rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/output/rdoc'
  rdoc.title = PKG_NAME
  rdoc.main = 'Webgen'
  rdoc.options << '--line-numbers' << '--inline-source' << '--promiscuous'
  rdoc.rdoc_files.include( 'lib/**/*.rb' )
  rdoc.rdoc_files.include( 'data/webgen/plugins/**/*.rb')
  rdoc.rdoc_files.exclude( /tc_.*\.rb$/ )
  rdoc.rdoc_files.exclude( 'data/webgen/plugins/**/vendor/**/*.rb')
end

tt = Rake::TestTask.new do |t|
  t.test_files = FileList['test/unittests/*.rb'] + FileList['data/webgen/plugins/**/test/unittests/*.rb']
end


# Release tasks ##############################################################


PKG_FILES = FileList.new( [
                           'Rakefile',
                           'TODO',
                           'setup.rb',
                           'VERSION',
                           'bin/webgen',
                           'lib/**/*.rb',
                           'data/**/*',
                           'test/**/*',
                           'doc/src/**/*'
                          ]) do |fl|
  #TODO
end

CLOBBER << "VERSION"
file 'VERSION' do
  puts "Generating VERSION file"
  File.open( 'VERSION', 'w+' ) {|file| file.write( PKG_VERSION + "\n" )}
end

Rake::PackageTask.new( PKG_NAME, PKG_VERSION ) do |p|
  p.need_tar = true
  p.need_zip = true
  p.package_files = PKG_FILES
end

if defined? Gem
  spec = Gem::Specification.new do |s|

    #### Basic information

    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.summary = PKG_SUMMARY
    s.description = PKG_DESCRIPTION

    #### Dependencies, requirements and files

    s.files = PKG_FILES.to_a
    s.add_dependency( 'cmdparse', '~> 2.0.0' )
    s.add_dependency( 'maruku', '>= 0.5.6' )
    s.add_dependency( 'facets', '>= 1.8.0')
    s.add_dependency( 'rake' )

    s.require_path = 'lib'

    s.executables = ['webgen']
    s.default_executable = 'webgen'

    #### Documentation

    s.has_rdoc = true
    s.extra_rdoc_files = rd.rdoc_files.reject {|fn| fn =~ /\.rb$/}.to_a
    s.rdoc_options = ['--line-numbers', '--inline-source', '--promiscuous', '--main', 'Webgen']

    #### Author and project details

    s.author = PKG_AUTHOR_NAME
    s.email = PKG_AUTHOR_EMAIL
    s.homepage = "http://#{RF_NAME}.rubyforge.org"
    s.rubyforge_project = RF_NAME
  end

  Rake::GemPackageTask.new( spec ) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

end

desc "Upload documentation to Rubyforge homepage"
task :publish_doc => [:doc] do
  sh "rsync -avz #{RF_SYNC_OPTIONS} doc/output/ gettalong@rubyforge.org:/var/www/gforge-projects/#{RF_NAME}/#{RF_DOC_PATH}/"
end

task :release => [:clean, :clobber, :package, :doc, :publish_doc]

if defined? RubyForge
  desc "Upload the release to Rubyforge"
  task :upload_on_rubyforge => [:package] do
    print 'Uploading files to Rubyforge for ' + PKG_FULLNAME + '...'
    rf = RubyForge.new
    rf.login

    #TODO: read from (to be created) changes file
    #rf.userconfig["release_notes"] =
    #rf.userconfig["release_changes"] =
    #rf.userconfig["preformatted"] = true

    files = %w[.gem .tgz .zip].collect {|ext| "pkg/#{PKG_FULLNAME}" + ext}

    rf.add_release(PKG_NAME, PKG_NAME, PKG_VERSION, *files)
    puts 'done'
  end

  desc 'Post announcement to rubyforge.'
  task :post_news do
    print 'Posting announcement to Rubyforge for ' + PKG_FULLNAME + '...'
    rf = RubyForge.new
    rf.login

    #TODO: read announcement from a doc page
    #rf.post_news(rubyforge_name, subject, body)
    puts "Posted to rubyforge"
  end

  task :release => [:upload_on_rubyforge, :post_news]
end


# Development tasks ##############################################################

if defined? Gem
  Rcov::RcovTask.new do |t|
    t.test_files = tt.instance_variable_get( :@test_files )
  end
end

# Helper methods ###################################################################
