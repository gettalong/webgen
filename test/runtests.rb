#!/usr/bin/env ruby
Dir[File.join(File.dirname(__FILE__), 'unittests/*')].each {|f| require f}
