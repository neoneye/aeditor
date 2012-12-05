require 'iterator'

class Scanner
	def initialize(iterator)
		@iterator = iterator
	end
	def execute
		a = @iterator.clone
		b = @iterator.clone
		c = @iterator.clone
		d = @iterator.clone
	end
end

class CountingIterator < Iterator::Collection
	@@count = 0
	def clone
		@@count += 1
		super()
	end
	def self.count; @@count end
	def close
		@@count -= 1
		super()
	end
end

class WrapperIterator < Iterator::Base
	def initialize(iterator, stack=nil)
		@iterator = iterator
		@stack = stack || []
	end
	def clone
		i = @iterator.clone
		@stack << i
		WrapperIterator.new(@iterator, @stack)
	end
	def close
		@stack.map{|i| i.close; nil}
	end
end

ary = (0..19).to_a
iterator = CountingIterator.new(ary)
#wrap_iterator = iterator
wrap_iterator = WrapperIterator.new(iterator)
s = Scanner.new(wrap_iterator)
s.execute
p CountingIterator.count
wrap_iterator.close # ensure all iterators gets closed
p CountingIterator.count
