# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/task'

class Webgen::Task::SampleTestTask

  def self.call(website, other)
    other
  end

end

class TestTask < MiniTest::Unit::TestCase

  def setup
    @website = :dummy
    @task = Webgen::Task.new(@website)
  end

  def test_register_and_data
    @task.register('SampleTestTask', :data => :data)
    assert(@task.registered?('sample_test_task'))
    assert_equal(:data, @task.data('sample_test_task'))

    @task.register('doit') {|website|}
    assert(@task.registered?('doit'))
  end

  def test_execute
    @task.register('SampleTestTask')
    @task.register('doit') do |website, param|
      [website, param]
    end

    assert_equal([@website, :data], @task.execute('doit', :data))
    assert_equal(:data, @task.execute('sample_test_task', :data))
  end

end
