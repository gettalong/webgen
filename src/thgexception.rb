
class ThgException < Exception

	attr_reader :solution

	def initialize(*args)
		id = args[0]
		if id.kind_of? Integer
			# use message map
			
			# set message
			super(substitute_entries(id, 0, args[1..-1]))
			# set solution
			@solution = substitute_entries(id, 1, args[1..-1])
		else
			# other exception
			@solution = id
		end
	end

	def substitute_entries(id, msgIndex, *args)
		args.flatten!
		@@messageMap[id][msgIndex].gsub(/%(\d+)/) { |match|
			args[$1.to_i]
		}
	end

	@@messageMap = {
		(CFG_ENTRY_NOT_FOUND = 1) => [
			"%0 entry not found", 
			"add entry %0 to the configuration file"
		],

		(CFG_FILE_NOT_FOUND = 2) => [
			"configuration file not found",
			"create the configuration file (current search path: %0)"
		],

		(ARG_PARSE_ERROR = 3) => [
			"%0: %1 %2 %3 %4 %5",
			"look at the online help to correct this error"
		],

		(PLUGIN_CFG_NOT_FOUND = 4) => [
			"the configuration file has no section for %0",
			"add entries for %0"
		],


	}

end
