# -*- ruby -*-
#
# $Id$
#
# webgen: a template based web page generator
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

require 'rake/clean'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'rake/testtask'

# General actions  ##############################################################

$:.push 'lib'
require 'webgen/configuration'

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


task :clean do
  ruby "setup.rb clean"
end


CLOBBER << "doc/output"
desc "Builds the documentation"
task :doc => [:rdoc] do
  chdir 'doc' do
    puts "\nGenerating online documentation..."
    ruby %{-I../lib ../bin/webgen -V 3 }
    puts "\nValidating all generated documentation..."
    sh 'find output/ -name "*.html" -exec xmllint --valid {} --catalogs --noout \;'
  end
end

rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/output/rdoc'
  rdoc.title    = PKG_NAME
  rdoc.options << '--line-numbers' << '--inline-source' << '-m README'
  rdoc.rdoc_files.include( 'README' )
  rdoc.rdoc_files.include( 'lib/**/*.rb' )
end


task :test do |t|
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
                            'install.rb',
                            'bin/**/*',
                            'lib/**/*.rb',
                            'testsite/**/*',
                            'tests/**/*',
                            'doc/**/*'
                          ]) do |fl|
  fl.exclude( /\bsvn\b/ )
  fl.exclude( 'testsite/output' )
  fl.exclude( 'testsite/coverage' )
  fl.exclude( 'doc/output' )
end

task :package => [:gen_files] do
  chdir 'pkg' do
    sh "rpaadmin packport #{PKG_NAME}-#{PKG_VERSION}"
  end
end

task :gen_changelog do
  sh "svn log -r HEAD:1 -v > ChangeLog"
end

task :gen_version do
  puts "Generating VERSION file"
  File.open( 'VERSION', 'w+' ) do |file| file.write( PKG_VERSION + "\n" ) end
end

task :gen_installrb do
  puts "Generating install.rb file"
  File.open( 'install.rb', 'w+' ) do |file|
    file.write "
require 'rpa/install'

class Install_#{PKG_NAME} < RPA::Install::FullInstaller
  name '#{PKG_NAME}'
  version '#{PKG_VERSION}-1'
  classification Application
  build do
    installdocs %w[COPYING ChangeLog TODO]
    installdocs 'docs'
    installrdoc %w[README] + Dir['lib/**/*.rb']
    installdata
  end
  description <<-EOF
#{PKG_SUMMARY}

#{PKG_DESCRIPTION}
  EOF
end
"
    end
end

task :gen_files => [:gen_changelog, :gen_version, :gen_installrb]
CLOBBER << "ChangeLog" << "VERSION" << "install.rb"

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

    s.require_path = 'lib'
    s.autorequire = nil

    s.executables = ['webgen']
    s.default_executable = 'webgen'

    #### Documentation

    s.has_rdoc = true
    s.extra_rdoc_files = rd.rdoc_files.reject do |fn| fn =~ /\.rb$/ end.to_a
    s.rdoc_options = ['--line-numbers', '-m README']

    #### Author and project details

    s.author = "Thomas Leitner"
    s.email = "t_leitner@gmx.at"
    s.homepage = "webgen.rubyforge.org"
    s.rubyforge_project = "webgen"
  end

  Rake::GemPackageTask.new( spec ) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

end

=begin
desc "Creates a tag in the repository"
task :tag do
  repositoryPath = File.dirname( $1 ) if `svn info` =~ /^URL: (.*)$/
  fail "Tag already created in repository " if /#{PKG_NAME}/ =~ `svn ls #{repositoryPath}/versions`
  sh "svn cp -m 'Created version #{PKG_NAME}' #{repositoryPath}/trunk #{repositoryPath}/versions/#{PKG_NAME}"
end
=end

desc "Upload documentation to homepage"
task :uploaddoc => [:doc] do
  Dir.chdir('doc/output')
  sh "scp -r * gettalong@rubyforge.org:/var/www/gforge-projects/#{PKG_NAME}/"
end


# Misc tasks ###################################################################


def count_lines( filename )
  lines = 0
  codelines = 0
  open( filename ) do |f|
    f.each do |line|
      lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      codelines += 1
    end
  end
  [lines, codelines]
end


def show_line( msg, lines, loc )
  printf "%6s %6s   %s\n", lines.to_s, loc.to_s, msg
end


desc "Show statistics"
task :statistics do
  total_lines = 0
  total_code = 0
  show_line( "File Name", "Lines", "LOC" )
  SRC_RB.each do |fn|
    lines, codelines = count_lines fn
    show_line( fn, lines, codelines )
    total_lines += lines
    total_code  += codelines
  end
  show_line( "Total", total_lines, total_code )
end


def run_testsite( arguments = '' )
  Dir.chdir("testsite")
  ruby %{-I../lib #{arguments} ../bin/webgen -V 3 }
end


CLOBBER << "testsite/output" << "testsite/webgen.log"
desc "Build the test site"
task :testsite do
  run_testsite
end


CLOBBER  << "testsite/coverage"
desc "Run the code coverage tool on the testsite"
task :coverage do
  run_testsite '-rcoverage'
end
