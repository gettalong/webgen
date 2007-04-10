#!/usr/bin/env ruby
Dir[File.join(File.dirname(__FILE__), 'unittests/*.rb')].each {|f| require f}
