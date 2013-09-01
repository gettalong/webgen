# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/website'
require 'tmpdir'
require 'yaml'
require 'set'

class TestExtensionDocumentation < Minitest::Test

  def test_all_extensions_documented
    ws = Webgen::Website.new(File.join(Dir.tmpdir, '/abcdefgh'))
    documentation = ws.ext.bundle_infos.extensions.dup
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
      if ws.ext.send(key).kind_of?(OpenStruct)
        ws.ext.send(key).instance_eval {@table.keys}.each do |s_key|
          check_docu.call("#{key}.#{s_key}")
        end
      end

      if ws.ext.send(key).respond_to?(:registered_extensions)
        ws.ext.send(key).registered_extensions.keys.each do |skey|
          skey = "#{key}.#{skey}"
          next if %w[tag.r tag.default].include?(skey)

          check_docu.call(skey)
        end
      end
    end

    check_docu.call('cli')
    assert(documentation.empty?, "Superfluous documentation keys: #{documentation.keys.join(", ")}")
  end

  def test_all_config_options_documented
    ws = Webgen::Website.new(File.join(Dir.tmpdir, '/abcdefgh'))
    documentation = ws.ext.bundle_infos.options.dup
    docu_keys = Set.new(documentation.keys)

    check_docu = lambda do |key|
      data = documentation.delete(key.to_s)
      assert(data, "Missing options documentation for '#{key}'")
      assert(!data['summary'].to_s.empty?, "Missing summary for option '#{key}'")
      assert(!data['syntax'].to_s.empty?, "Missing syntax for option '#{key}'")
      assert(data['example'].kind_of?(Hash) && data['example'].length > 0, "Missing example for option '#{key}'")
    end

    ws.config.options.each do |key, value|
      check_docu.call(key.to_s)
    end
    assert(documentation.empty?, "Superfluous option documentation keys: #{documentation.keys.join(", ")}")
  end

end
