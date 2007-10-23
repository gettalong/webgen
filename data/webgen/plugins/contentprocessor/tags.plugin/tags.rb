require 'yaml'
require 'strscan'

module ContentProcessor

  class Tags

    def init_plugin
      @start_re = /(\\*)\{#{param('prefix')}(\w+)(::?)/
      @end_re = /(\\*)\{#{param('prefix')}(\w+)\}/
    end

    def process( context )
      replace_tags( context.content, context.ref_node ) do |tag, param_string, body|
        log(:debug) { "Replacing tag #{tag} with data '#{param_string}' and body '#{body}' in <#{context.ref_node.node_info[:src]}>" }

        result = ''
        processor = processor_for_tag( tag )
        if !processor.nil?
          processor.set_params( processor.tag_params( param_string, context.ref_node ) )
          result, process_output = processor.process_tag( tag, body, context )
          processor.set_params( nil )

          result = process( context.clone( :content => result ) ).content if process_output
        end

        result
      end
      context
    end

    #######
    private
    #######

    BRACKETS_RE = /([{}])/
    ProcessingStruct = Struct.new( :state, :tag, :simple_tag, :backslashes, :brackets, :start_pos, :end_pos,
                                   :params_start_pos, :params_end_pos, :body_end_pos )

    def replace_tags( content, node )
      scanner = StringScanner.new( content )
      data = ProcessingStruct.new(:before_tag)
      while true
        case data.state
        when :before_tag
          if scanner.skip_until( @start_re )
            data.state = :in_start_tag
            data.backslashes = scanner[1].length
            data.brackets = 1
            data.tag = scanner[2]
            data.simple_tag = scanner[3] == ':'
            data.params_start_pos = scanner.pos
            data.start_pos = scanner.pos - scanner.matched.length
          else
            data.state = :done
          end

        when :in_start_tag
          data.brackets += (scanner[1] == '{' ? 1 : -1) while data.brackets != 0 && scanner.skip_until( BRACKETS_RE )
          if data.brackets != 0
            log(:error) { "Unbalanced curly brackets in <#{node.node_info[:src]}>!" }
            data.state = :done
          else
            data.params_end_pos = data.body_end_pos = data.end_pos = scanner.pos - 1
            data.state = (data.simple_tag ? :process : :in_body)
          end

        when :process
          if data.backslashes % 2 == 0
            result = yield( data.tag, scanner.string[data.params_start_pos...data.params_end_pos],
                            scanner.string[(data.params_end_pos+1)...data.body_end_pos] ).to_s
            scanner.string[data.start_pos..data.end_pos] = "\\" * (data.backslashes / 2) + result
            scanner.pos = data.start_pos + result.length
          else
            scanner.string[data.start_pos, 1 + data.backslashes / 2] = ''
            scanner.pos -= 1 + data.backslashes / 2
          end
          data.state = :before_tag

        when :in_body
          while (result = scanner.skip_until( @end_re ))
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
            log(:error) { "Invalid body part in <#{node.node_info[:src]}>!" }
            data.state = :done
          end

        when :done
          break
        end
      end
      scanner.string
    end

    # Returns the tag processor for +tag+ or +nil+ if +tag+ is unknown.
    def processor_for_tag( tag )
      tags = registered_tags
      if tags.has_key?( tag )
        tags[tag]
      elsif tags.has_key?( :default )
        tags[:default]
      else
        log(:error) { "No tag processor for tag #{tag.inspect} found" }
      end
    end

    # Returns a hash of the registered tag plugins, with the tag names as keys.
    def registered_tags
      if !defined?( @tags ) || @cached_plugins_hash != @plugin_manager.plugin_infos.keys.hash
        @tags = {}
        @plugin_manager.plugin_infos[/^Tag\//].each do |k,v|
          next if (plugin = @plugin_manager[k]).nil?
          plugin.tags.each do |tag|
            unless @tags[tag].nil?
              log(:info) { "Tag #{tag} redefined, using plugin #{plugin.plugin_name} instead of #{@tags[tag].plugin_name}" }
            end
            @tags[tag] = plugin
          end
        end
        @cached_plugins_hash = @plugin_manager.plugin_infos.keys.hash
      end
      @tags
    end

  end

end
