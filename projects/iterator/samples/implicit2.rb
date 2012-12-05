require 'iterator'

class FibonacciIterator < Iterator::Base
	def initialize
		super()
		first
	end
	def first 
		@value = 1 
		@value_next = 1 
	end
	def next 
		tmp, @value = @value, @value_next
		@value_next += tmp
	end
	def has_next?; true end  # infinity
	def current; @value end
end

i = FibonacciIterator.new
p Array.copy_n(i, 10)  #=> [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
i.close
