
class ThgException < RuntimeError

	attr_reader :solution

	def initialize(*args)
		# set message
		super(substitute_entries(args[0], 0, args[1..-1]))
		# set solution
		@solution = substitute_entries(args[0], 1, args[1..-1])
	end

	def substitute_entries(id, msgIndex, *args)
		args.flatten!
		@@messageMap[id][msgIndex].gsub(/%(\d+)/) { |match|
			args[$1.to_i].to_s
		}
	end

	private :substitute_entries

	### Class variables and methods ###

	@@messageMap = Hash.new

	def ThgException.add_entry(symbol, message, solution)
		name = symbol.id2name
		raise ThgException.new(EXCEPTION_SYMBOL_INVALID, symbol, caller[0]) if !(('A'..'Z') === name[0..0])
		raise ThgException.new(EXCEPTION_SYMBOL_IS_DEFINED, symbol, caller[0]) if const_defined? name

		# declare the constant
		class_eval("#{name} = #{name.hash}")

		# add the hash entries
		@@messageMap[name.hash] = [message, solution]
	end


	ThgException.add_entry :EXCEPTION_SYMBOL_INVALID,
		"the symbol %0 does not start with an upper case letter (%1)",
		"change the name of the symbol so that it starts with an upper case letter"

	ThgException.add_entry :EXCEPTION_SYMBOL_IS_DEFINED,
		"the symbol %0 is already defined (%1)",
		"change the name of the symbol"

end
