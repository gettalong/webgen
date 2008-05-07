require 'test/unit'
require 'webgen/languages'

class TestLanguages < Test::Unit::TestCase

  def test_get_language
    assert_nil(Webgen::LanguageManager.language_for_code(nil))

    lang1 = Webgen::LanguageManager.language_for_code('ger')
    lang2 = Webgen::LanguageManager.language_for_code('deu')
    lang3 = Webgen::LanguageManager.language_for_code('de')
    lang4 = Webgen::LanguageManager.language_for_code('en')

    [lang1, lang2, lang3, lang4].each {|lang| assert_kind_of(Webgen::Language, lang)}
    assert_equal(lang1, lang2)
    assert_equal(lang3, lang2)
    assert_not_equal(lang4, lang2)
  end

  def test_find_language
    langs = Webgen::LanguageManager.find_language('greek')
    assert_equal(2, langs.length)
    assert_equal('gre', langs[0].code3chars)
    assert_equal('grc', langs[1].code3chars)
  end

  def test_language_accessors
    lang = Webgen::LanguageManager.language_for_code('ger')
    assert_equal('ger', lang.code3chars)
    assert_equal('deu', lang.code3chars_alternative)
    assert_equal('de', lang.code2chars)
  end

  def test_other_methods
    de = Webgen::LanguageManager.language_for_code('ger')
    assert_equal('de', de)
    assert_equal(de, 'de')
    assert_equal("de", de.to_s)
    assert_equal("Implicitly de", "Implicitly " + de)
    assert_kind_of(String, de.inspect)
  end

  def test_sort_method
    ger = Webgen::LanguageManager.language_for_code('ger')
    eng = Webgen::LanguageManager.language_for_code('en')
    ace = Webgen::LanguageManager.language_for_code('ace')

    assert_equal(-1, ger <=> eng)
    assert_equal(-1, ace <=> ger)
    assert_equal(-1, ace <=> eng)
  end

end
