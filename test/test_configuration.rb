require 'test/unit'
require 'webgen/configuration'

class TestConfiguration < Test::Unit::TestCase

  def test_defining_options
    @config = Webgen::Configuration.new
    @config.test.value(:value, :opts => true)
    assert_equal(:value, @config['test.value'])
    assert_equal({:opts => true}, @config.meta_info['test.value'])
    @config.test.value(:other_value, :doc => true)
    assert_equal(:value, @config['test.value'])
    assert_equal({:opts => true, :doc => true}, @config.meta_info['test.value'])
    @config.test.other(:value)
    assert_equal({}, @config.meta_info['test.other'])
  end

  def test_get_options
    @config = Webgen::Configuration.new
    @config.test.value(:value)
    assert_equal(:value, @config['test.value'])
    assert_raise(ArgumentError) { @config['not.existing']}
  end

  def test_set_options
    @config = Webgen::Configuration.new
    @config.test.value(:value)
    assert_equal(:value, @config['test.value'])
    @config['test.value'] = :newvalue
    assert_equal(:newvalue, @config['test.value'])

    assert_raise(ArgumentError) { @config['not.existing'] = :newvalue}
  end

end
