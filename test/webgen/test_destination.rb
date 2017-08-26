# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/destination'

class Webgen::Destination::MyDestination

  def initialize(website); end

end

class TestDestination < Minitest::Test

  def setup
    @website = MiniTest::Mock.new
    @dest = Webgen::Destination.new(@website)
  end

  def test_register
    @dest.register('Webgen::Destination::MyDestination')
    assert(@dest.registered?('my_destination'))

    @dest.register('MyDestination')
    assert(@dest.registered?('my_destination'))

    @dest.register('MyDestination', :name => 'test')
    assert(@dest.registered?('test'))

    assert_raises(ArgumentError) { @dest.register('doit') { "nothing" } }
  end

  def test_instance
    @dest.register('MyDestination')

    @website.expect(:config, {'destination' => 'unknown'})
    assert_raises(Webgen::Error) { @dest.instance_eval { instance } }
    @website.verify

    @website.expect(:config, {'destination' => 'my_destination'})
    assert_kind_of(Webgen::Destination::MyDestination, @dest.instance_eval { instance })
    @website.verify

    @website.expect(:config, {'destination' => 'unknown'})
    @dest.instance_eval { instance } # nothing should be raised
    #@website.verify
  end

end
