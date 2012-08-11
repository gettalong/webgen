# -*- encoding: utf-8 -*- -*- ruby -*-

# load all optional developer libraries
require 'rubygems/package_task'
require 'rdoc/task'
require 'rdoc/rdoc'

begin
  require 'rubyforge'
rescue LoadError
end

require 'fileutils'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'

$:.unshift('lib')
require 'webgen/webgentask'
require 'webgen/version'
require 'webgen/page'

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

desc "Build the whole user documentation"
task :doc => [:rdoc, :htmldoc]

desc "Generate the HTML documentation"
Webgen::WebgenTask.new('htmldoc') do |site|
  site.clobber_outdir = true
  site.config_block = lambda do |config|
    config['sources'] = [['/', "Webgen::Source::FileSystem", 'doc'],
                         ['/', "Webgen::Source::FileSystem", 'misc', 'default.*'],
                         ['/', "Webgen::Source::FileSystem", 'misc', 'htmldoc.metainfo'],
                         ['/', "Webgen::Source::FileSystem", 'misc', 'htmldoc.virtual'],
                         ['/', "Webgen::Source::FileSystem", 'misc', 'images/**/*']]
    prefix = "webgen-website-bundle-"
    config['resources'].select {|name, data| name =~ /^#{prefix}style/}.each do |name, data|
      config['sources'] <<
        ["/references/website_styles/#{name.sub(prefix, '')}/", "Webgen::Source::FileSystem", 'misc', 'style.page']
      config['sources'] <<
        ["/references/website_styles/#{name.sub(prefix, '')}/", 'Webgen::Source::Resource', name, '/src/**', '/src/']
    end
    config['output'] = ['Webgen::Output::FileSystem', 'htmldoc']
    config.default_processing_pipeline('Page' => 'erb,tags,kramdown,blocks,fragments')
  end
end

rd = RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'htmldoc/rdoc'
  rdoc.title = 'webgen'
  rdoc.main = 'lib/webgen/website.rb'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('lib')
end

Rake::TestTask.new do |test|
  test.test_files = FileList['test/webgen/**/test_*.rb']
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

  begin
    REL_PAGE = Webgen::Page.from_data(File.read('website/src/news/release_' + Webgen::VERSION.split('.').join('_') + '.page'))
  rescue
    puts 'NO RELEASE NOTES/CHANGES FILE'
  end

  PKG_FILES = FileList.new([
                            'Rakefile',
                            'setup.rb',
                            'VERSION',
                            'ChangeLog',
                            'AUTHORS',
                            'THANKS',
                            'COPYING',
                            'GPL',
                            'bin/webgen',
                            'data/**/*',
                            'doc/**/*',
                            'lib/**/*.rb',
                            'man/man1/webgen.1',
                            'misc/**/*',
                            'test/**/*',
                           ]) do |fl|
    fl.exclude('data/**/.gitignore')
  end

  CLOBBER << "VERSION"
  file 'VERSION' do
    puts "Generating VERSION file"
    File.open('VERSION', 'w+') {|file| file.write(Webgen::VERSION + "\n")}
  end

  CLOBBER << 'ChangeLog'
  file 'ChangeLog' do
    puts "Generating ChangeLog file"
    `git log --name-only > ChangeLog`
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
    s.post_install_message = <<EOF

Thanks for choosing webgen! Here are some places to get you started:
* The webgen User Documentation at <http://webgen.rubyforge.org/documentation/index.html>
* The mailing list archive at <http://rubyforge.org/pipermail/webgen-users/>
* The webgen Wiki at <http://github.com/gettalong/webgen/wiki>

Have a look at <http://webgen.rubyforge.org/news/index.html> for a list of changes!

Have fun!

EOF

    #### Dependencies, requirements and files

    s.required_ruby_version = '>= 1.9.2'

    s.add_dependency('cmdparse', '>= 2.0.5')
    s.add_dependency('systemu', '>= 2.5.0')
    s.add_dependency('kramdown', '= 0.10.0')
    s.add_development_dependency('rake', '>= 0.8.3')
    s.add_development_dependency('rubyforge', '>= 2.0.2')
    s.add_development_dependency('maruku', '>= 0.6.0')
    s.add_development_dependency('RedCloth', '>= 4.1.9')
    s.add_development_dependency('haml', '>= 3.1.0')
    s.add_development_dependency('sass', '>= 3.2.0')
    s.add_development_dependency('builder', '>= 2.1.0')
    s.add_development_dependency('rdoc', '>= 3.0')
    s.add_development_dependency('coderay', '>= 1.0.0')
    s.add_development_dependency('erubis', '>= 2.6.5')
    s.add_development_dependency('rdiscount', '>= 1.3.5')
    s.add_development_dependency('archive-tar-minitar', '>= 0.5.2')

    s.files = PKG_FILES.to_a
    s.require_path = 'lib'
    s.executables = ['webgen']
    s.default_executable = 'webgen'

    #### Documentation

    s.has_rdoc = true
    s.rdoc_options = ['--line-numbers', '--main', 'lib/webgen/website.rb']

    #### Author and project details

    s.author = 'Thomas Leitner'
    s.email = 't_leitner@gmx.at'
    s.homepage = "http://webgen.rubyforge.org"
    s.rubyforge_project = 'webgen'
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

  desc 'Release webgen version ' + Webgen::VERSION
  task :release => [:clobber, :package, :publish_files, :publish_doc, :website, :publish_website, :post_news]

  desc "Upload webgen documentation to Rubyforge homepage"
  task :publish_doc => [:doc] do
    sh "rsync -avc --delete htmldoc/ gettalong@rubyforge.org:/var/www/gforge-projects/webgen/documentation/#{(Webgen::VERSION.split('.')[0..-2] + ['x']).join('.')}"
  end

  if defined? RubyForge
    desc "Upload the release to Rubyforge"
    task :publish_files => [:package] do
      print 'Uploading files to Rubyforge...'
      $stdout.flush

      rf = RubyForge.new
      rf.configure
      rf.login

      rf.userconfig["release_notes"] = REL_PAGE.blocks['notes'].content
      rf.userconfig["release_changes"] = REL_PAGE.blocks['changes'].content
      rf.userconfig["preformatted"] = false

      files = %w[.gem .tgz .zip].collect {|ext| "pkg/webgen-#{Webgen::VERSION}" + ext}

      rf.add_release('webgen', 'webgen', Webgen::VERSION, *files)

      sh "gem push pkg/webgen-#{Webgen::VERSION}.gem"

      puts 'done'
    end

    desc 'Post announcement to rubyforge.'
    task :post_news do
      print 'Posting announcement to Rubyforge ...'
      $stdout.flush
      rf = RubyForge.new
      rf.configure
      rf.login

      rf.post_news('webgen', "webgen #{Webgen::VERSION} released", REL_PAGE.blocks['notes'].content)
      puts "done"
    end
  end

  desc 'Generates the webgen website'
  Webgen::WebgenTask.new(:website) do |site|
    site.directory = 'website'
    site.clobber_outdir = true
    site.config_block = lambda do |config|
      config['sources'] += [['/documentation/', 'Webgen::Source::FileSystem', '../doc'],
                            ['/', "Webgen::Source::FileSystem", '../misc', 'default.less.css'],
                            ['/documentation/', "Webgen::Source::FileSystem", '../misc', 'htmldoc.virtual'],
                            ['/', "Webgen::Source::FileSystem", '../misc', 'images/**/*']]
      prefix = "webgen-website-bundle-"
      config['resources'].select {|name, data| name =~ /^#{prefix}style/}.each do |name, data|
        config['sources'] <<
          ["/documentation/references/website_styles/#{name.sub(prefix, '')}/", "Webgen::Source::FileSystem", '../misc', 'style.page']
        config['sources'] <<
          ["/documentation/references/website_styles/#{name.sub(prefix, '')}/", 'Webgen::Source::Resource', name, '/src/**', '/src/']
      end
      config.default_processing_pipeline('Page' => 'erb,tags,kramdown,blocks,fragments')
    end
  end

  desc "Upload the webgen website to Rubyforge"
  task :publish_website => ['rdoc', :website] do
    sh "rsync -avc --delete --exclude documentation/rdoc --exclude 'documentation/0.5.x' --exclude 'documentation/0.4.x' --exclude 'wiki' --exclude 'robots.txt'  website/out/ gettalong@rubyforge.org:/var/www/gforge-projects/webgen/"
    sh "rsync -avc --delete htmldoc/rdoc/ gettalong@rubyforge.org:/var/www/gforge-projects/webgen/documentation/rdoc"
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

  EXCLUDED_FOR_TESTS=FileList.new(['lib/webgen/bundle/**',
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
