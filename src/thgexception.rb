class ThaumaturgeException < Exception
	attr_reader :solution

	def initialize(solution)
		@solution = solution
	end
end
