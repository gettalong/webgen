# -*- encoding: utf-8 -*-

require 'webgen/extension_manager'

module Webgen

  # Namespace for all tasks.
  #
  # Tasks provide the main entrance point for doing things with a website, like creating it,
  # generating it, and much more.
  #
  # == Implementing a task
  #
  # A task object only needs to respond to one method called +call+ which takes the website as first
  # parameter and may take an arbitrary number of additional arguments. The method should return
  # +true+ if the task was executed sucessfully or else +false+.
  #
  # Due to this there are basically two ways to implement a task since: Either as a class with a
  # class method called +call+. Or as a Proc object.
  #
  # If the task needs to be configured to work correctly, use configuration options!
  #
  # The task has to be registered so that webgen knows about it, see ::register for more
  # information.
  #
  # == Sample Task
  #
  # The following sample task just outputs the value of its configuration option:
  #
  #   class OutputTask
  #
  #     def self.call(website, options)
  #       website.logger.vinfo("The output task configuration value follows")
  #       website.logger.info(website.config['task.output.option'])
  #       true
  #     end
  #
  #   end
  #
  #   website.config.define_option('task.output.option', nil, 'The configuration option')
  #   website.ext.task.register OutputTask, :name => 'output'
  #
  class Task

    include Webgen::ExtensionManager

    # Create a new item tracker for the given website.
    def initialize(website)
      super()
      @website = website
    end

    # Register a task. The parameter +klass+ can either be a String containing the name of a
    # class/module (which has to respond to :call) or an object that responds to :call. If the class
    # is located under this namespace, only the class name without the hierarchy part is needed,
    # otherwise the full class/module name including parent module/class names is needed.
    #
    # Instead of registering an object that responds to :call, you can also provide a block that
    # does not take any parameters.
    #
    # === Options:
    #
    # [:name] The name for the task. If not set, it defaults to the snake-case version of the class
    #         name (without the hierarchy part). It should only contain letters.
    #
    # [:data] Associates arbitrary data with the task object. This data can be retrieved using the
    #         #data method.
    #
    # === Examples:
    #
    #   task.register('CreateWebsite')     # registers Webgen::Task::CreateWebsite
    #
    #   task.register('::CreateWebsite')   # registers CreateWebsite !!!
    #
    #   task.register('doit') do |website|
    #     # task commands go here
    #   end
    #
    def register(klass, options={}, &block)
      name = do_register(klass, options, true, &block)
      ext_data(name).data = options[:data]
    end

    # Execute the task identified by the given name.
    def execute(name, *options)
      extension(name).call(@website, *options)
    end

    # Return the task data for the given task.
    def data(name)
      ext_data(name).data
    end

  end

end
