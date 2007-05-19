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

desc "Installs the package #{PKG_NAME}"
task :install => [:prepare] do
  ruby "setup.rb config"
  ruby "setup.rb setup"
  ruby "setup.rb install"
end


CLEAN.exclude( 'doc/src/documentation/plugins/core' )
CLEAN.exclude( 'doc/output/documentation/plugins/core' )
task :clean do
  ruby "setup.rb clean"
end


desc "Creates the whole documentation"
task :doc => [:rdoc]

rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/output/rdoc'
  rdoc.title    = PKG_NAME
  rdoc.options << '--line-numbers' << '--inline-source' << '-m README'
  rdoc.rdoc_files.include( 'README' )
  rdoc.rdoc_files.include( 'lib/**/*.rb' )
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/unittests/*.rb']
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = FileList['test/unittests/*.rb']
  end
rescue LoadError
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
                           'test/**/*',
                           'doc/**/*',
                           'man/**/*',
                          ]) do |fl|
  fl.exclude( /\bsvn\b/ )
  fl.exclude( 'doc/output' )
end

CLOBBER << "ChangeLog"
task :gen_changelog do
  puts "Generating Changelog file"
  sh "svk log -r HEAD:1 -v > ChangeLog"
end

CLOBBER << "VERSION"
task :gen_version do
  puts "Generating VERSION file"
  File.open( 'VERSION', 'w+' ) {|file| file.write( PKG_VERSION + "\n" )}
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
    s.add_dependency( 'redcloth', '>= 3.0.0' )
    s.add_dependency( 'rake' )

    s.require_path = 'lib'

    s.executables = ['webgen']
    s.default_executable = 'webgen'

    #### Documentation

    s.has_rdoc = true
    s.extra_rdoc_files = rd.rdoc_files.reject {|fn| fn =~ /\.rb$/}.to_a
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
