# -*- encoding: utf-8 -*-

require 'yaml'
require 'webgen/loggable'
require 'webgen/websiteaccess'

# This module should be mixed into any class that wants to serve as a webgen tag class. Have a look
# a the example below to see how a basic tag class looks like.
#
# == Tag classes
#
# A tag class is a webgen extension that handles specific webgen tags. webgen tags are used to add
# dynamic content to page and template files and are made for ease of use.
#
# A tag class can handle multiple different tags. Just add a (tag name)-(class name) pair to the
# <tt>contentprocessor.tags.map</tt> configuration entry for each tag name you want to associate
# with the tag class. The special name <tt>:default</tt> is used for the default tag class which is
# called if a tag with an unknown tag name is encountered.
#
# The only method needed to be written is +call+ which is called by the tags content processor to
# the actual processing. And the +initialize+ method must not take any parameters!
#
# Tag classes *can* also choose to not use this module. If they don't use it they have to provide
# the following methods: +set_params+, +create_tag_params+, +call+.
#
# == Tag parameters
#
# webgen tags allow the specification of parameters in the tag definition. The method
# +tag_params_list+ returns all configuration entries that can be set this way. And the method
# +tag_config_base+ is used to resolve partially stated configuration entries. The default method
# uses the full class name, strips a <tt>Webgen::</tt> part at the beginning away, substitutes
# <tt>.</tt> for <tt>::</tt> and makes everything lowercase.
#
# An additional configuration entry option is also used: <tt>:mandatory</tt>. If this key is set to
# +true+ for a configuration entry, the entry counts as mandatory and needs to be set in the tag
# definition. If this key is set to +default+, this means that this entry should be the default
# mandatory parameter (used when only a string is provided in the tag definition). There *should* be
# only one default mandatory parameter.
#
# == Sample Tag Class
#
# Following is a simple tag class example which just reverses the body text and adds some
# information about the context to the result. Note that the class does not reside in the
# Webgen::Tag namespace and that the configuration entry is therefore also not under the
# <tt>tag.</tt> namespace.
#
#   class Reverser
#
#     include Webgen::Tag::Base
#
#     def call(tag, body, context)
#       result = param('do_reverse') ? body.reverse : body
#       result += "Node: " + context.content_node.absolute_lcn + " (" + context.content_node['title'] + ")"
#       result += "Reference node: " + context.ref_node.absolute_lcn
#       result
#     end
#
#   end
#
#   WebsiteAccess.website.config.reverser.do_reverse nil, :mandatory => default
#   WebsiteAccess.website.config['contentprocessor.tags.map']['reverse'] = 'Reverser'
#
module Webgen::Tag::Base

  include Webgen::Loggable
  include Webgen::WebsiteAccess

  # Return a hash with parameter values extracted from the string +tag_config+.
  def create_tag_params(tag_config, ref_node)
    begin
      config = YAML::load("--- #{tag_config}")
    rescue ArgumentError => e
      log(:error) { "Could not parse the tag params '#{tag_config}' in <#{ref_node.absolute_lcn}>: #{e.message}" }
      config = {}
    end
    create_params_hash(config, ref_node)
  end

  # Set the current parameter configuration to +params+.
  def set_params(params)
    @params = params
  end

  # Retrieve the parameter value for +name+. The value is taken from the current parameter
  # configuration if the parameter is specified there or from the website configuration otherwise.
  def param(name)
    (@params && @params.has_key?(name) ? @params[name] : website.config[name])
  end

  # Default implementation for processing a tag. The parameter +tag+ specifies the name of the tag
  # which should be processed (useful for tag classes which process different tags).
  #
  # The parameter +body+ holds the optional body value for the tag.
  #
  # The +context+ parameter holds all relevant information for processing. Have a look at the
  # Webgen::Context class to see what is available.
  #
  # The method has to return the result of the tag processing and, optionally, a boolean value
  # specifying if the result should further be processed (ie. webgen tags replaced).
  #
  # Needs to be redefined by classes that mixin this module!
  def call(tag, body, context)
    raise NotImplementedError
  end

  #######
  private
  #######

  # The base part of the configuration name. This isthe class name without the Webgen module
  # downcased and all "::" substituted with "." (e.g. Webgen::Tag::Menu -> tag.menu). By overriding
  # this method one can provide a different way of specifying the base part of the configuration
  # name.
  def tag_config_base
    self.class.name.gsub('::', '.').gsub(/^Webgen\./, '').downcase
  end

  # Return the list of all parameters for the tag class. All configuration options starting with
  # +tag_config_base+ are used.
  def tag_params_list
    regexp = /^#{tag_config_base}/
    website.config.data.keys.select {|key| key =~ regexp}
  end

  # Create the parameter hash from +config+ which needs to be a Hash, a String or +nil+.
  def create_params_hash(config, node)
    params = tag_params_list
    result = case config
             when Hash then create_from_hash(config, params, node)
             when String then create_from_string(config, params, node)
             when NilClass then {}
             else
               log(:error) { "Invalid parameter type (#{config.class}) for tag '#{self.class.name}' in <#{node.absolute_lcn}>" }
               {}
             end

    unless params.all? {|k| !website.config.meta_info[k][:mandatory] || result.has_key?(k)}
      log(:error) { "Not all mandatory parameters for tag '#{self.class.name}' in <#{node.absolute_lcn}> set" }
    end

    result
  end

  # Return a valid parameter hash taking values from +config+ which has to be a Hash.
  def create_from_hash(config, params, node)
    result = {}
    config.each do |key, value|
      if params.include?(key)
        result[key] = value
      elsif params.include?(tag_config_base + '.' + key)
        result[tag_config_base + '.' + key] = value
      else
        log(:warn) { "Invalid parameter '#{key}' for tag '#{self.class.name}' in <#{node.absolute_lcn}>" }
      end
    end
    result
  end

  # Return a valid parameter hash by setting +value+ to the default mandatory parameter.
  def create_from_string(value, params, node)
    param_name = params.find {|k| website.config.meta_info[k][:mandatory] == 'default'}
    if param_name.nil?
      log(:error) { "No default mandatory parameter specified for tag '#{self.class.name}' but set in <#{node.absolute_lcn}>"}
      {}
    else
      {param_name => value}
    end
  end

end
