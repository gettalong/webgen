require 'yaml'
require 'ups/ups'
require 'thgexception'

class Tags < UPS::Plugin

    NAME = "Tags"
    SHORT_DESC = "Super plugin for handling tags"

	ThgException.add_entry :UNKNOWN_TAG,
        "found tag {%0: ...} for which no plugin exists",
		"either remove the tag or implement a plugin for it"

    attr_accessor :tags

    def initialize
        @tags = Hash.new
    end


	def substitute_tags( content, node, templateNode )
		content.gsub!(/\{(\w+):\s+(\{.*?\}|.*?)\}/) do |match|
            tag = YAML::load( "- #{$2}" )[0]
            #TODO log4r
			#Configuration.instance.debug("Replacing tag: #{$1}, match: #{match}")
			raise ThgException.new( :UNKNOWN_TAG, $1 ) unless @tags.has_key? $1
			@tags[$1].process_tag( tag, node, templateNode )
		end
	end

end


UPS::Registry.register_plugin Tags
