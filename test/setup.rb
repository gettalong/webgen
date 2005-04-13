require 'webgen/plugin'

class MockLogger

  attr_accessor :level
  attr_accessor :log_dev_set

  def set_log_dev( dev )
    @log_dev_set = true
  end

  def error( progname = nil, &block )
  end

  def warn( progname = nil, &block )
  end

  def info( progname = nil, &block )
  end

  def debug( progname = nil, &block )
  end

end

class Object

  @@logger = MockLogger.new

end
