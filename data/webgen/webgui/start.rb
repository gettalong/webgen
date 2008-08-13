#!/usr/bin/env ruby
require 'rubygems'

# fix for bug in Windows version of ramaze-2008.06 when win32console is not installed
require 'ramaze/snippets'
require 'ramaze/log/informer'
Ramaze::Informer = Ramaze::Logging::Logger::Informer
require 'ramaze'

# require all controllers and models
acquire __DIR__/:controller/'*'
acquire __DIR__/:model/'*'

Ramaze.start :adapter => :webrick, :port => 7000
