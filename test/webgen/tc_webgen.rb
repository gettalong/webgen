require 'test/unit'
require 'webgen/webgen'
require 'setup'

class WebgenMainTest < Test::Unit::TestCase

  def setup
    @o = Webgen::WebgenMain.new
  end

  def assert_parse_options_result( tested )
    main, data = @o.parse_options( tested['options'] )
    assert_equal( tested['main'], main )
    assert_equal( tested['data'], data )
  end

  def default_parse_options_result
    {'options'=>[], 'main'=>@o.method( :runMain ),
     'data'=>{}
    }
  end

  def test_parse_options
    assert_parse_options_result( default_parse_options_result )
    opts = default_parse_options_result
    opts['options'] = ['-p']
    opts['main'] = @o.method( :runListPlugins )
    assert_parse_options_result( opts )
    opts = default_parse_options_result
    opts['options'] = ['-c']
    opts['main'] = @o.method( :runListConfiguration )
    assert_parse_options_result( opts )

    logger.log_dev_set = false
    opts = default_parse_options_result
    opts['options'] = ['-C', 'config.file', '-S', 'source', '-O', 'destination', '-V', '5', '-L']
    opts['data']['configfile'] = 'config.file'
    opts['data']['srcDirectory'] = 'source'
    opts['data']['outDirectory'] = 'destination'
    opts['data']['verbosityLevel'] = 5
    assert_parse_options_result( opts )
    assert( logger.log_dev_set )
  end

end
