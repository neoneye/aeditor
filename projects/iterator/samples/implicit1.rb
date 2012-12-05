require 'iterator'

class ImplicitIterator < Iterator::Base
	def initialize
		super()
		first
	end
	def first; @value = 0 end
	def next; @value += 1 end
	def has_next?; @value < 10 end
	def current; @value end
end

i = ImplicitIterator.new
while i.has_next?
	p i.current
	i.next
end
i.close
