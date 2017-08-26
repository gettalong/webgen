# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/cli/logger'

class TestLogger < Minitest::Test

  def test_initialize
    l = Webgen::CLI::Logger.new
    assert_equal(::Logger::INFO, l.level)
  end

  def test_log_output
    original = Webgen::CLI::Utils.use_colors
    Webgen::CLI::Utils.use_colors = false
    out, _err = capture_io do
      l = Webgen::CLI::Logger.new
      l.level = ::Logger::DEBUG
      l.info { "information" }
      l.info { "[create] information" }
      l.info { "[update] information" }
      l.info { "[delete] information" }
      l.warn { "warning" }
      l.error{ "error" }
      l.debug('program') { "debug" }
    end
    expected = <<EOF
INFO  information
INFO  [create] information
INFO  [update] information
INFO  [delete] information
WARN  warning
ERROR error
DEBUG (program) debug
EOF
    assert_equal(expected, out)
  ensure
    Webgen::CLI::Utils.use_colors = original
  end

end
