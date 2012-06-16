# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/website'
require 'tmpdir'
require 'yaml'
require 'set'

class TestExtensionDocumentation < MiniTest::Unit::TestCase

  def test_all_extensions_documented
    ws = Webgen::Website.new(File.join(Dir.tmpdir, '/abcdefgh'))
    documentation = YAML::load(File.read(ws.ext.bundles['built-in']))['extensions']
    author = "Thomas Leitner <t_leitner@gmx.at>"
    docu_keys = Set.new(documentation.keys)
    ext_keys = Set.new(ws.ext.instance_eval { @table.keys })

    check_docu = lambda do |key|
      data = documentation.delete(key.to_s)
      assert(data, "Missing documentation key '#{key}'")
      assert(!data['summary'].to_s.empty?, "Missing summary for key '#{key}'")
      assert(!data['author'].to_s.empty?, "Missing author for key '#{key}'")
    end

    ext_keys.each do |key|
      check_docu.call(key.to_s)

      if ws.ext.send(key).respond_to?(:registered_extensions)
        ws.ext.send(key).registered_extensions.keys.each do |skey|
          skey = "#{key}.#{skey}"
          skey = "tag.meta_info" if skey == "tag.default"
          next if %w[tag.r].include?(skey)

          check_docu.call(skey)
        end
      end
    end

    check_docu.call('cli')
    assert(documentation.empty?, "Superfluous documentation keys: #{documentation.keys.join(", ")}")
  end

end
