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
  nil
end

require 'rake/clean'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'rake/testtask'

# General actions  ##############################################################

if `ruby -Ilib ./bin/webgen --version` =~ /\s([.0-9]*?)(\s*\(.*\))?$/
  PKG_VERSION = $1
else
  PKG_VERSION = "0.0.0"
end

PKG_NAME = "webgen-#{PKG_VERSION}"

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


desc "Installs Webgen"
task :install => [:prepare]
task :install do
  ruby "setup.rb install"
end


task :clean do
  ruby "setup.rb clean"
end


CLOBBER << "doc/output" << "doc/webgen.log"
desc "Builds the documentation"
task :doc => [:rdoc] do
  Dir.chdir("doc")
  ruby %{-I../lib ../bin/webgen -V 4 }
  Dir.chdir("..")
end

rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/output/rdoc'
  rdoc.title    = "Webgen"
  rdoc.options << '--line-numbers' << '--inline-source' << '-m README'
  rdoc.rdoc_files.include( 'README' )
  rdoc.rdoc_files.include( 'lib/**/*.rb' )
end



Rake::TestTask.new do |t|
  t.pattern = "tests/**/*.rb"
  t.verbose = true
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
                            'bin/**/*',
                            'lib/**/*.rb',
                            'testsite/**/*',
                            'tests/**/*',
                            'doc/**/*'
                          ]) do |fl|
  fl.exclude( /\bsvn\b/ )
  fl.exclude( 'testsite/output' )
  fl.exclude( 'testsite/coverage' )
  fl.exclude( 'testsite/webgen.log' )
  fl.exclude( 'doc/output' )
  fl.exclude( 'doc/webgen.log' )
end

if !defined? Gem
  puts "Package Target requires RubyGEMs"
else
  spec = Gem::Specification.new do |s|

    #### Basic information

    s.name = 'webgen'
    s.version = PKG_VERSION
    s.summary = "Templated based weg page generator"
    s.description = <<-EOF
      Webgen is a web page generator implemented in Ruby. It is used to
      generate static web pages from templates and page description files.
    EOF

    #### Dependencies, requirements and files

    # does not work for me
    s.add_dependency( 'log4r', '> 1.0.4' )
    s.files = PKG_FILES.to_a

    s.require_path = 'lib'
    s.autorequire = nil

    s.bindir = 'bin'
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

  task :package => [:generateFiles]
  task :generateFiles do |t|
    sh "svn log -r HEAD:1 -v > ChangeLog"
    File.open('VERSION', 'w+') do |file| file.write( PKG_VERSION + "\n" ) end
  end

  CLOBBER << "ChangeLog" << "VERSION"

  Rake::GemPackageTask.new( spec ) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

end


desc "Creates a tag in the repository"
task :tag do
  repositoryPath = File.dirname( $1 ) if `svn info` =~ /^URL: (.*)$/
  fail "Tag already created in repository " if /#{PKG_NAME}/ =~ `svn ls #{repositoryPath}/versions`
  sh "svn cp -m 'Created version #{PKG_NAME}' #{repositoryPath}/trunk #{repositoryPath}/versions/#{PKG_NAME}"
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
