class MockLogger

  attr_accessor :level

  def set_log_dev( dev )
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

  remove_const :LOGGER
  LOGGER = MockLogger.new

end
