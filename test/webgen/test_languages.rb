# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/languages'

class TestLanguages < Minitest::Test

  def test_get_language
    assert_nil(Webgen::LanguageManager.language_for_code(nil))

    lang1 = Webgen::LanguageManager.language_for_code('ger')
    lang2 = Webgen::LanguageManager.language_for_code('deu')
    lang3 = Webgen::LanguageManager.language_for_code('de')
    lang4 = Webgen::LanguageManager.language_for_code('en')

    [lang1, lang2, lang3, lang4].each {|lang| assert_kind_of(Webgen::Language, lang)}
    assert_equal(lang1, lang2)
    assert_equal(lang3, lang2)
    refute_equal(lang4, lang2)
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

  def test_hashing
    de = Webgen::LanguageManager.language_for_code('ger')
    en = Webgen::LanguageManager.language_for_code('en')
    h = {'de' => de, en => en}
    assert_equal(de, h[de])
    assert_equal(de, h['de'])
    assert_equal(en, h[en])
    refute_equal(en, h['en']) # bc 'en'.eql?(en) is false
    assert_equal(Webgen::LanguageManager.language_for_code('en'),
                 Webgen::LanguageManager.language_for_code(en))
  end

  def test_loaded_languages
    # Languages should only be loaded from DATA section, after __END__ line
    path = Webgen::LanguageManager.method(:languages).source_location.first
    ignored_line = File.readlines(path).first
    keys = Webgen::LanguageManager.languages.keys
    refute_includes keys, ignored_line
    refute_includes keys, ignored_line.chomp
  end
end
