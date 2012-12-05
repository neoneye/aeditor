require 'iterator'
class MultiIterator < Iterator::Base
	def initialize(*iterators)
		@iterators = iterators
		first
	end
	def first; @iterators.each{|i| i.first} end
	def next; @iterators.each{|i| i.next} end
	def is_done?
		@iterators.each{|i| return true if i.is_done? }
		false
	end
	def current; @iterators end
end

a = %w(a b c d e).create_iterator
b = (0..4).to_a.create_iterator
i = MultiIterator.new(a, b)
until i.is_done?
	ia, ib = i.current
	p [ia.current, ib.current]
	i.next
end
i.close
a.close
b.close
