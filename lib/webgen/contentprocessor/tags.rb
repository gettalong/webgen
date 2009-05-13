# -*- encoding: utf-8 -*-

require 'yaml'
require 'strscan'
require 'webgen/tag'

module Webgen::ContentProcessor

  # Processes special webgen tags to provide dynamic content.
  #
  # webgen tags are an easy way to add dynamically generated content to websites, for example menus
  # or breadcrumb trails.
  class Tags

    include Webgen::WebsiteAccess
    include Webgen::Loggable

    def initialize #:nodoc:
      @start_re = /(\\*)\{#{website.config['contentprocessor.tags.prefix']}(\w+)(::?)/
      @end_re = /(\\*)\{#{website.config['contentprocessor.tags.prefix']}(\w+)\}/
    end

    # Replace all webgen tags in the content of +context+ with the rendered content.
    def call(context)
      replace_tags(context.content, context.ref_node) do |tag, param_string, body|
        log(:debug) { "Replacing tag #{tag} with data '#{param_string}' and body '#{body}' in <#{context.ref_node.absolute_lcn}>" }
        process_tag(tag, param_string, body, context)
      end
      context
    end

    # Process the +tag+ and return the result. The parameter +params+ needs to be a Hash holding all
    # needed and optional parameters for the tag or a parameter String in YAML format and +body+ is
    # the optional body for the tag. +context+ needs to be a valid Webgen::Context object.
    def process_tag(tag, params, body, context)
      result = ''
      processor = processor_for_tag(tag)
      if !processor.nil?
        params = if params.kind_of?(String)
                   processor.create_tag_params(params, context.ref_node)
                 else
                   processor.create_params_hash(params, context.ref_node)
                 end
        processor.set_params(params)
        result, process_output = processor.call(tag, body, context)
        processor.set_params(nil)

        result = call(context.clone(:content => result)).content if process_output
      end
      result
    end


    #######
    private
    #######

    BRACKETS_RE = /([{}])/
    ProcessingStruct = Struct.new(:state, :tag, :simple_tag, :backslashes, :brackets, :start_pos, :end_pos,
                                  :params_start_pos, :params_end_pos, :body_end_pos)

    # Return the +content+ provided by +node+ with all webgen tags replaced. When a webgen tag is
    # encountered by the parser, the method yields all found information and substitutes the
    # returned string for the tag.
    def replace_tags(content, node) #:yields: tag_name, param_string, body
      scanner = StringScanner.new(content)
      data = ProcessingStruct.new(:before_tag)
      while true
        case data.state
        when :before_tag
          if scanner.skip_until(@start_re)
            data.state = :in_start_tag
            data.backslashes = scanner[1].length
            data.brackets = 1
            data.tag = scanner[2]
            data.simple_tag = (scanner[3] == ':')
            data.params_start_pos = scanner.pos
            data.start_pos = scanner.pos - scanner.matched.length
          else
            data.state = :done
          end

        when :in_start_tag
          data.brackets += (scanner[1] == '{' ? 1 : -1) while data.brackets != 0 && scanner.skip_until(BRACKETS_RE)
          if data.brackets != 0
            log(:error) { "Unbalanced curly brackets in <#{node.absolute_lcn}>!" }
            data.state = :done
          else
            data.params_end_pos = data.body_end_pos = data.end_pos = scanner.pos - 1
            data.state = (data.simple_tag ? :process : :in_body)
          end

        when :process
          if data.backslashes % 2 == 0
            result = yield(data.tag, scanner.string[data.params_start_pos...data.params_end_pos],
                            scanner.string[(data.params_end_pos+1)...data.body_end_pos]).to_s
            scanner.string[data.start_pos..data.end_pos] = "\\" * (data.backslashes / 2) + result
            scanner.pos = data.start_pos + result.length
          else
            scanner.string[data.start_pos, 1 + data.backslashes / 2] = ''
            scanner.pos -= 1 + data.backslashes / 2
          end
          data.state = :before_tag

        when :in_body
          while (result = scanner.skip_until(@end_re))
            next unless scanner[2] == data.tag
            if scanner[1].length % 2 == 1
              scanner.string[(scanner.pos - scanner.matched.length), 1 + scanner[1].length / 2] = ''
              scanner.pos -= 1 + scanner[1].length / 2
            else
              break
            end
          end
          if result
            data.state = :process
            data.end_pos = scanner.pos - 1
            data.body_end_pos = scanner.pos - scanner.matched.length + scanner[1].length / 2
          else
            log(:error) { "Invalid body part in <#{node.absolute_lcn}>!" }
            data.state = :done
          end

        when :done
          break
        end
      end
      scanner.string
    end

    # Return the tag processor for +tag+ or +nil+ if +tag+ is unknown.
    def processor_for_tag(tag)
      map = website.config['contentprocessor.tags.map']
      klass = if map.has_key?(tag)
                map[tag]
              elsif map.has_key?(:default)
                map[:default]
              else
                log(:error) { "No tag processor for tag #{tag.inspect} found" }
                nil
              end
      klass.nil? ? nil : website.cache.instance(klass)
    end

  end

end
