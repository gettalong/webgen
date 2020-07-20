# -*- encoding: utf-8 -*- -*- ruby -*-

# load all optional developer libraries
require 'rubygems/package_task'
require 'rdoc/task'
require 'rdoc/rdoc'

require 'fileutils'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'

$:.unshift('lib')
require 'webgen/version'

# End user tasks ###############################################################

task :default => :test

desc "Install using setup.rb"
task :install do
  ruby "setup.rb config"
  ruby "setup.rb setup"
  ruby "setup.rb install"
end

task :clobber do
  ruby "setup.rb clean"
end

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'webgen'
  rdoc.main = 'API.rdoc'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('lib', 'API.rdoc')
end

Rake::TestTask.new do |test|
  test.test_files = FileList['test/**/test_*.rb']
end

# Release tasks and development tasks ############################################

namespace :dev do

  SUMMARY = 'webgen is a fast, powerful, and extensible static website generator.'
  DESCRIPTION = <<EOF
webgen is used to generate static websites from templates and content
files (which can be written in a markup language). It can generate
dynamic content like menus on the fly and comes with many powerful
extensions.
EOF

  PKG_FILES = FileList.new([
                            'Rakefile',
                            'setup.rb',
                            'VERSION',
                            'AUTHORS',
                            'THANKS',
                            'COPYING',
                            'GPL',
                            'API.rdoc',
                            'README.md',
                            'bin/webgen',
                            'data/**/*',
                            'data/**/.gitignore',
                            'lib/**/*',
                            'man/man1/webgen.1',
                            'test/**/*',
                           ])

  CLOBBER << "VERSION"
  file 'VERSION' do
    puts "Generating VERSION file"
    File.open('VERSION', 'w+') {|file| file.write(Webgen::VERSION + "\n")}
  end

  Rake::PackageTask.new('webgen', Webgen::VERSION) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
    pkg.package_files = PKG_FILES
  end

  spec = Gem::Specification.new do |s|

    #### Basic information
    s.name = 'webgen'
    s.version = Webgen::VERSION
    s.summary = SUMMARY
    s.description = DESCRIPTION
    s.license = 'GPL'
    s.post_install_message = <<EOF

Thanks for choosing webgen! Here are some places to get you started:
* The webgen User Documentation at <http://webgen.gettalong.org/documentation/>
* The mailing list archive at <https://groups.google.com/forum/?fromgroups#!forum/webgen-users>
* The webgen Wiki at <http://github.com/gettalong/webgen/wiki>

Have a look at <http://webgen.gettalong.org/news.html> for a list of changes!

Have fun!

EOF

    #### Dependencies, requirements and files

    s.required_ruby_version = '>= 2.0.0'

    s.add_dependency('cmdparse', '~> 3.0', '>= 3.0.1')
    s.add_dependency('systemu', '~> 2.5')
    s.add_dependency('kramdown', '~> 2.3')
    s.add_development_dependency('rake', '>= 0.8.3')
    s.add_development_dependency('minitest', '~> 5.0')
    s.add_development_dependency('diff-lcs', '~> 1.0')
    s.add_development_dependency('maruku', '~> 0.7')
    s.add_development_dependency('RedCloth', '~> 4.1')
    s.add_development_dependency('haml', '~> 4.0')
    s.add_development_dependency('sass', '~> 3.2')
    s.add_development_dependency('builder', '~> 2.1')
    s.add_development_dependency('rdoc', '~> 4.0')
    s.add_development_dependency('coderay', '~> 1.0')
    s.add_development_dependency('erubis', '~> 2.6')
    s.add_development_dependency('rdiscount', '~> 1.3')
    s.add_development_dependency('archive-tar-minitar', '~> 0.5')
    s.add_development_dependency('cssminify', '~> 1.0')

    s.files = PKG_FILES.to_a
    s.require_path = 'lib'
    s.executables = ['webgen']
    s.default_executable = 'webgen'

    #### Documentation

    s.has_rdoc = true
    s.rdoc_options = ['--line-numbers', '--main', 'API.rdoc']
    s.extra_rdoc_files = ['API.rdoc']

    #### Author and project details

    s.author = 'Thomas Leitner'
    s.email = 't_leitner@gmx.at'
    s.homepage = "http://webgen.gettalong.org"
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

  desc 'Release webgen version ' + Webgen::VERSION
  task :release => [:clobber, :package, :publish_files]

  desc "Upload the release to rubygems.org"
  task :publish_files => [:package] do
    sh "gem push pkg/webgen-#{Webgen::VERSION}.gem"
    puts 'done'
  end

  desc "Run the tests one by one to check for missing deps"
  task :test_isolated do
    files = Dir['test/webgen/**/test_*']
    puts "Checking #{files.length} tests"
    failed = files.select do |file|
      okay = system("ruby -Ilib #{file} 2>&1 >/dev/null")
      print(okay ? '.' : 'E')
      !okay
    end
    puts
    failed.each {|file| puts "Problem with" + file.rjust(60) }
  end

  EXCLUDED_FOR_TESTS=FileList.new(['lib/webgen/bundle/**/*',
                                   'lib/webgen/context/*',
                                   'lib/webgen/cli/*',
                                   'lib/webgen/test_helper',
                                   'lib/webgen/path_handler/directory.rb',
                                   'lib/webgen/version.rb',
                                  ])

  EXCLUDED_FOR_DOCU=FileList.new(['lib/webgen/cli{*,**/*}',
                                  'lib/webgen/*/base.rb',
                                  'lib/webgen/context/*',
                                  'lib/webgen/context.rb'
                                 ])

  desc "Checks for missing test/docu"
  task :check_missing do
    puts 'Files for which no test exists:'
    Dir['lib/webgen/**/*'].each do |path|
      next if File.directory?(path) || EXCLUDED_FOR_TESTS.include?(path)
      test_path = 'test/' + path.gsub(/lib\/(.*)\/(.*).rb/, '\1/test_\2.rb')
      puts ' '*4 + path unless File.exists?(test_path)
    end
=begin
    puts
    puts 'Files for which no docu exists:'
    Dir['lib/webgen/*/*'].each do |path|
      next if EXCLUDED_FOR_DOCU.include?(path)
      docu_path = 'doc/' + path.gsub(/lib\/webgen\//, "").gsub(/\.rb$/, '.page')
      puts ' '*4 + path unless File.exists?(docu_path)
    end
=end
  end

end

task :clobber => ['dev:clobber']

# Helper methods ###################################################################
