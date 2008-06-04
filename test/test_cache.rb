require 'test/unit'
require 'webgen/cache'

class TestCache < Test::Unit::TestCase

  def setup
    @cache = Webgen::Cache.new
  end

  def dump_and_restore
    data = @cache.dump
    setup
    @cache.restore(data)
  end

  def test_standard_cache
    @cache[:key] = :value
    assert_equal(:value, @cache[:key])
    dump_and_restore
    assert_equal(:value, @cache[:key])
    @cache[:key] = :newvalue
    assert_equal(:value, @cache[:key])
    dump_and_restore
    assert_equal(:newvalue, @cache[:key])
  end

  def test_permanent_cache
    @cache.permanent[:key] = :value
    assert_equal(:value, @cache.permanent[:key])
    dump_and_restore
    assert_equal(:value, @cache.permanent[:key])
  end

  def test_volatile_cache
    @cache.volatile[:key] = :value
    assert_equal(:value, @cache.volatile[:key])
    dump_and_restore
    assert_equal(nil, @cache.volatile[:key])

    @cache.volatile[:key] = :value
    obj = @cache.instance('Hash')
    @cache.reset_volatile_cache
    assert_equal(nil, @cache.volatile[:key])
    assert_equal(obj, @cache.instance('Hash'))
  end

  def test_instance
    obj = @cache.instance('Hash')
    assert_kind_of(Hash, obj)
    assert_equal(obj, @cache.instance('Hash'))
    @cache.instance('Array')
    assert_equal(['Hash', 'Array'], @cache.permanent[:classes])
    dump_and_restore
    assert_not_nil(@cache.volatile[:classes]['Hash'])
  end

end
