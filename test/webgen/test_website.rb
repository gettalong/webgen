# -*- encoding: utf-8 -*-

require 'fileutils'
require 'tmpdir'
require 'minitest/autorun'
require 'webgen/website'

class TestWebsite < Minitest::Test

  def test_initialize
    i = 0
    ws = Webgen::Website.new('dir') do |website, before|
      if i == 0
        assert_equal(true, before)
      else
        assert_equal(false, before)
      end
      i += 1
    end
    assert(ws.blackboard)
    assert(ws.cache)
    assert(ws.config)
    assert(ws.tree)
    assert_equal('dir', ws.directory)
  end

  def test_read_config_file
    Dir.mktmpdir do |dir|
      File.open(File.join(dir, 'webgen.config'), 'w+') {|f| f.write('- unknown')}
      assert_raises(Webgen::Configuration::Error) { Webgen::Website.new(dir) }

      File.open(File.join(dir, 'webgen.config'), 'w+') {|f| f.write("# ruby\nwebsitesdf'] =")}
      assert_raises(Webgen::Error) { Webgen::Website.new(dir) }

      File.open(File.join(dir, 'webgen.config'), 'w+') {|f| f.write('website.lang: de')}
      ws = Webgen::Website.new(dir)
      assert_equal('de', ws.config['website.lang'])

      File.open(File.join(dir, 'webgen.config'), 'w+') {|f| f.write("# -*- ruby -*-\nwebsite.config['website.lang'] = 'de'")}
      ws = Webgen::Website.new(dir)
      assert_equal('de', ws.config['website.lang'])
    end
  end

end
