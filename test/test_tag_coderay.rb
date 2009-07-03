# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tag'

class TestTagCoderay < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::Coderay.new
  end

  def call(context, body, lang, process, css = 'style')
    @obj.set_params({'tag.coderay.lang' => lang,
                      'tag.coderay.process' => process,
                      'tag.coderay.css' => css})
    result = @obj.call('coderay', body, context)
    @obj.set_params({})
    result
  end

  def test_call
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/', {'title' => 'Hallo'})
    context = Webgen::Context.new(:chain => [root])

    assert(call(context, 'TestData', 'html', false).include?('TestData'))
    assert(call(context, '{title:}', :ruby, true).include?('Hallo'))

    assert(call(context, 'TestData', 'ruby', false, 'other').include?('class="co"'))
    assert(!@website.tree['/stylesheets/coderay-default.css'])

    @website.blackboard.del_listener(:node_meta_info_changed?, Webgen::SourceHandler::Main.new.method(:meta_info_changed?))
    @website.config['passive_sources'] << ['/', "Webgen::Source::Resource", "webgen-passive-sources"]
    assert(call(context, 'TestData', 'ruby', false, 'class').include?('class="co"'))
    assert(@website.tree['/stylesheets/coderay-default.css'])
    assert_equal('stylesheets/coderay-default.css', context.persistent[:cp_head][:css_file].first)
  end

end
