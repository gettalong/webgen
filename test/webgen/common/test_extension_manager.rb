# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/common/extension_manager'

class DummyExtensionManager

  include Webgen::Common::ExtensionManager
  extend ClassMethods

  def register(name, value)
    @extensions[name] = [value]
  end

end

class TestExtensionManager < MiniTest::Unit::TestCase

  def setup
    @dummy = DummyExtensionManager.new
  end

  def test_registered_names
    assert_kind_of(Array, @dummy.registered_names)
    assert_empty(@dummy.registered_names)
    @dummy.register('key', 'value')
    assert_equal(['key'], @dummy.registered_names)
  end

  def test_registered
    refute(@dummy.registered?('key'))
    @dummy.register('key', 'value')
    assert(@dummy.registered?('key'))
  end

  def test_normalize_class_name
    klass, name = @dummy.send(:normalize_class_name, "Klass", false)
    assert_equal("DummyExtensionManager::Klass", klass)
    assert_equal("Klass", name)
    klass, name = @dummy.send(:normalize_class_name, "MyKlass", false)
    assert_equal("DummyExtensionManager::MyKlass", klass)
    assert_equal("MyKlass", name)
    klass, name = @dummy.send(:normalize_class_name, "My::Klass", false)
    assert_equal("My::Klass", klass)
    assert_equal("Klass", name)
    klass, name = @dummy.send(:normalize_class_name, "klass", false)
    assert_equal("DummyExtensionManager::klass", klass)
    assert_equal("klass", name)
  end

  def test_do_register
    @dummy.send(:do_register, "Klass", {:type => 'test'}, [:type])
    assert_equal(['DummyExtensionManager::Klass', 'test'],  @dummy.instance_eval { @extensions['klass'] })
  end

  def test_extension
    @dummy.register('key', 'DummyExtensionManager')
    assert_equal(DummyExtensionManager, @dummy.send(:extension, "key"))
  end

  def test_resolve_class
    assert_equal(DummyExtensionManager, @dummy.send(:resolve_class, DummyExtensionManager))
    assert_equal(DummyExtensionManager, @dummy.send(:resolve_class, 'DummyExtensionManager'))
  end

  def test_static_extension_manager
    static = DummyExtensionManager.static
    assert_kind_of(Webgen::Common::ExtensionManager, static)
    DummyExtensionManager.register('key', 'value')
    assert_equal(['key'], static.registered_names)
  end

  def test_clone
    static = DummyExtensionManager.static
    static.register('key', 'value')
    cloned = static.clone
    cloned.register('key1', 'value1')
    refute(static.registered?('key1'))
    assert(cloned.registered?('key'))
    assert(cloned.registered?('key1'))
  end

end
