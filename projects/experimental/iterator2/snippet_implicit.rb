require 'iterator'

class ImplicitIterator < Iterator::Base
	def initialize
		super()
		first
	end
	def first; @value = 0 end
	def next; @value += 1 end
	def is_done?; @value >= 10 end
	def current; @value end
end

i = ImplicitIterator.new
until i.is_done?
	p i.current
	i.next
end
i.close
