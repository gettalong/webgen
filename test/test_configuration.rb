require 'test/unit'
require 'webgen/configuration'
require 'webgen/sourcehandler'

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

  def test_set_options_using_helpers
    @config = Webgen::Configuration.new
    @config.sourcehandler.default_meta_info({'Webgen::SourceHandler::Page' => {'in_menu' => true}})
    @config.sourcehandler.patterns({'Webgen::SourceHandler::Page' => ['**/*.page']})

    @config.default_meta_info('Page' => {'in_menu' => false, 'test' => true})
    assert_equal({'in_menu' => false, 'test' => true}, @config['sourcehandler.default_meta_info']['Webgen::SourceHandler::Page'])
    @config.default_meta_info('Webgen::SourceHandler::Page' => {'in_menu' => true, :action => 'replace'})
    assert_equal({'in_menu' => true}, @config['sourcehandler.default_meta_info']['Webgen::SourceHandler::Page'])
    @config.default_meta_info('Other' => {'in_menu' => false})
    assert_equal({'in_menu' => false}, @config['sourcehandler.default_meta_info']['Other'])
    assert_raise(ArgumentError) { @config.default_meta_info([5,6]) }

    @config.patterns('Page' => ['**/*.html'])
    assert_equal(['**/*.html'], @config['sourcehandler.patterns']['Webgen::SourceHandler::Page'])
    @config.patterns('Page' => {'del' => ['**/*.html'], 'add' => ['**/*.page']})
    assert_equal(['**/*.page'], @config['sourcehandler.patterns']['Webgen::SourceHandler::Page'])
    @config.patterns('Other' => {'del' => ['**/*.html'], 'add' => ['**/*.page']})
    assert_equal(['**/*.page'], @config['sourcehandler.patterns']['Other'])
    assert_raise(ArgumentError) { @config.patterns([5,6]) }
    assert_raise(ArgumentError) { @config.patterns('Page' => 5) }
  end

end
