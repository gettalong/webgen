# -*- ruby -*-

begin
    require 'rubygems'
    require 'rake/gempackagetask'
rescue Exception
    nil
end

require 'rake/packagetask'
require 'rake/clean'
require 'rake/rdoctask'


# General actions  ##############################################################

if `ruby -Ilib ./bin/thaumaturge --version` =~ /\S+$/
  PKG_VERSION = $&
else
  PKG_VERSION = "0.0.0"
end

CLOBBER << "thg.log"

PKG_NAME = "thaumaturge-#{PKG_VERSION}"

SRC_RB = FileList['lib/**/*.rb']

# The default task is run if rake is given no explicit arguments.

#desc "Default Task"
#task :default => :test


# End user tasks ################################################################

desc "Prepares for installation"
task :prepare do
    ruby "setup.rb config"
    ruby "setup.rb setup"
end


desc "Installs Thaumaturge"
task :install => [:prepare]
task :install do
    ruby "setup.rb install"
end


task :clean do
    ruby "setup.rb clean"
end


rd = Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = "Thaumaturge"
    rdoc.options << '--line-numbers' << '--inline-source' << '--main README'
    rdoc.rdoc_files.include( 'README' )
    rdoc.rdoc_files.include( 'lib/**/*.rb' )
end


# Developer tasks ##############################################################


PKG_FILES = FileList.new( [
    'setup.rb',
    'ChangeLog',
    'Statistics',
    'TODO',
    'Rakefile',
    'bin/**/*',
    'lib/**/*.rb',
    'testSite/**/*'
]) do |fl|
    fl.exclude(/\bsvn\b/)
    fl.exclude('testSite/output')
    fl.exclude('testSite/thg.log')
end

if !defined? Gem
    puts "Package Target requires RubyGEMs"
else
    spec = Gem::Specification.new do |s|

        #### Basic information

        s.name = 'thaumaturge'
        s.version = PKG_VERSION
        s.summary = "Templated based weg page generator"
        s.description = <<-EOF
          Thaumaturge is a web page generator implemented in Ruby. It is used to
          generate static web pages from templates and page description files.
        EOF

        #### Dependencies, requirements and files

        s.add_dependency('log4r', '> 1.0.4')
        s.files = PKG_FILES.to_a

        s.require_path = 'lib'
        s.autorequire = 'thaumaturge'
        s.bindir = 'bin'
        s.executables = ['thaumaturge']
        s.default_executable = 'thaumaturge'

        #### Documentation

        s.has_rdoc = true
        s.extra_rdoc_files = rd.rdoc_files.reject do |fn| fn =~ /\.rb$/ end.to_a
        s.rdoc_options = rd.options

        #### Author and project details

        s.author = "Thomas Leitner"
        s.email = "t_leitner@gmx.at"
        #s.homepage = "TBD"
        #s.rubyforge_project = "TBD"
    end

    task :package => [:generateFiles]
    task :generateFiles do |t|
        sh "svn log -r HEAD:1 -v > ChangeLog"
        sh "rake statistics > Statistics"
        lines = File.readlines("Statistics")[1..-1]
        File.open("Statistics", "w") do |file| file.write lines end
    end

    CLOBBER << "ChangeLog" << "Statistics"

    Rake::GemPackageTask.new(spec) do |pkg|
        pkg.need_zip = true
        pkg.need_tar = true
    end

end

desc "Creates a tag in the repository"
task :tag do
    repositoryPath = File.dirname($1) if `svn info` =~ /^URL: (.*)$/
    fail "Tag already created in repository " if /#{PKG_NAME}/ =~ `svn ls #{repositoryPath}/versions`
    sh "svn cp -m 'Created version #{PKG_NAME}' #{repositoryPath}/trunk #{repositoryPath}/versions/#{PKG_NAME}"
end


# Misc tasks ###################################################################


def count_lines(filename)
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


def show_line(msg, lines, loc)
    printf "%6s %6s   %s\n", lines.to_s, loc.to_s, msg
end


desc "Show statistics"
task :statistics do
    total_lines = 0
    total_code = 0
    show_line("File Name", "Lines", "LOC")
    SRC_RB.each do |fn|
        lines, codelines = count_lines(fn)
        show_line(fn, lines, codelines)
        total_lines += lines
        total_code  += codelines
    end
    show_line("Total", total_lines, total_code)
end


desc "Build the test site"
task :buildtestsite do
    Dir.chdir("testSite")
    ruby %{-I../lib ../lib/thg/thg.rb -v 3 }
end
