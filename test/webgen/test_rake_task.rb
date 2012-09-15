# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/rake_task'

class TestRakeTask < MiniTest::Unit::TestCase

  include Rake

  def test_create
    site = Webgen::RakeTask.new('doit') do |s|
      s.clobber_outdir = true
      s.config_block = lambda {|c| c}
      s.directory = 'website'
    end
    assert_equal('website', site.directory)
    assert_equal(true, site.clobber_outdir)
    assert_equal(5, site.config_block[5])
    assert(Task['doit'])
    assert(Task['clobber_doit'])
  end

end
