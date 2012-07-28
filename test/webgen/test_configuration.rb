# -*- encoding: utf-8 -*-

require 'tmpdir'
require 'stringio'

require 'minitest/autorun'
require 'webgen/configuration'

class TestConfiguration < MiniTest::Unit::TestCase

  def setup
    @config = Webgen::Configuration.new
    add_default_option
  end

  def add_default_option
    @config.define_option('namespace.option', 'default', 'desc') {|v| raise "Error with option" unless v.kind_of?(String); v}
  end

  def test_defining_options
    assert(@config.options['namespace.option'])
    assert_equal('default', @config.options['namespace.option'].default)
    assert_equal('desc', @config.options['namespace.option'].description)
    assert_kind_of(Proc, @config.options['namespace.option'].validator)

    assert_raises(ArgumentError) { add_default_option }
  end

  def test_has_option
    assert(@config.option?('namespace.option'))
    refute(@config.option?('unknown.option'))
  end

  def test_get_option_value
    assert_equal('default', @config['namespace.option'])
    assert_raises(Webgen::Configuration::Error) { @config['unknown'] }

    @config.define_option('other', :sym, 'desc')
    assert_equal(:sym, @config['other'])
  end

  def test_set_and_modify_option_value
    @config['namespace.option'].tr!('de', 'en')
    assert_equal('default', @config['namespace.option'])
    assert_equal('default', @config.options['namespace.option'].default)
    @config['namespace.option'] = 'other'
    assert_equal('other', @config['namespace.option'])

    assert_raises(Webgen::Configuration::Error) { @config['namespace.option'] = :other }
    assert_raises(Webgen::Configuration::Error) { @config['unknown'] = 'other' }
  end

  def test_set_values
    result = @config.set_values('namespace.option' => 'other')
    assert_empty(result)
    assert_equal('other', @config['namespace.option'])

    result = @config.set_values('namespace' => {'option' => 'new', 'opt2' => :val}, 'other' => :val)
    assert_equal(['namespace.opt2', 'other'], result)
    assert_equal('new', @config['namespace.option'])

    assert_raises(Webgen::Configuration::Error) { @config.set_values('namespace.option' => :test) }
  end

  def test_frozen_config
    @config.freeze
    assert_equal('default', @config['namespace.option'])
    assert_raises(Webgen::Configuration::Error) { @config['namespace.option'] = 'other' }
    assert_raises(RuntimeError) { @config.define_option('nonsense', 'val', 'desc') }
  end

  def test_load_from_file_exceptions
    assert_raises(ArgumentError) { @config.load_from_file(5) }
    assert_raises(Webgen::Configuration::Error) { @config.load_from_file(StringIO.new("[namespace.option, test]")) }
    assert_raises(Webgen::Configuration::Error) { @config.load_from_file(StringIO.new("[asdfds")) }
  end

  def test_load_value_from_file
    Dir.mktmpdir('webgen-configuration') do |dir|
      file = File.join(dir, 'config.yaml')
      File.open(file, 'w+') {|f| f.write("namespace.option: test")}

      assert_empty(@config.load_from_file(file))
      assert_equal('test', @config['namespace.option'])
    end
  end

  def test_load_value_from_io
    assert_empty(@config.load_from_file(StringIO.new("namespace.option: test")))
    assert_equal('test', @config['namespace.option'])
  end

  def test_initialize_copy
    @config.set_values({'namespace.option' => 'value'})
    @config.freeze

    cloned = @config.clone
    assert(@config.frozen?)
    assert_raises(Webgen::Configuration::Error) { cloned['namespace.option'] = 'other' }
    assert_raises(RuntimeError) { cloned.define_option('nonsense', 'val', 'desc') }

    dupped = @config.dup
    refute(dupped.frozen?)

    dupped.define_option('test', '', '')
    assert(dupped.option?('test'))
    refute(@config.option?('test'))

    dupped.set_values({'namespace.option' => 'other'})
    assert_equal('other', dupped['namespace.option'])
    assert_equal('value', @config['namespace.option'])
  end

end
