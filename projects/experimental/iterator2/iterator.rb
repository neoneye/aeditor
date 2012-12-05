module Iterator

# purpose:
# base class for bidirectional iterators
# similar to the example in the GoF-Design Patterns book (page 257)
class Base
	def close; end
	def first; nil end
	def next; nil end
	def is_done?; true end
	def last; nil end
	def prev; nil end
	def current; nil end
	def current=(value); nil end
	def each
		first
		until is_done?
			yield(current)
			self.next
		end
	end
	def reverse_each
		last
		until is_done?
			yield(current)
			self.prev
		end
	end
	def reverse
		Reverse.new(self)
	end
	include Enumerable
end

# purpose:
# iterate over a collection (Array and similar classes)
#
# functions:
# * bidirectional
class Collection < Iterator::Base
	attr_reader :position
	def initialize(data)
		@data = data
		first
	end
	def first; @position = 0 end
	def next; @position += 1 end
	def last; @position = @data.size-1 end
	def prev; @position -= 1 end
	def is_done?; (@position < 0) or (@position >= @data.size) end
	def current; @data[@position] end
	def current=(value); @data[@position] = value end
end

# purpose:
# a decorator which reverses the direction of an iterator
#
# functions:
# * bidirectional
class Reverse < Iterator::Base
	def initialize(iterator); @i = iterator end
	def position; @i.position end
	def first; @i.last end
	def next; @i.prev end
	def last; @i.first end
	def prev; @i.next end
	def is_done?; @i.is_done? end
	def current; @i.current end
	def current=(value); @i.current = value end
end

# purpose:
# make one iterator out of to iterators
#
# functions:
# * bidirectional
class Range < Iterator::Base
	def initialize(start, stop)
		super()
		@start = start
		@stop = stop
		first
	end
	def position; @i.position end
	def first; @i = @start.clone end
	def next; @i.next end
	def last; @i = @stop.clone end
	def prev; @i.prev end
	def is_done? 
		(@i.position < @start.position) or (@i.position > @stop.position)
	end
	def current; @i.current; end
	def current=(value); @i.current = value; end
end

# purpose:
# concat many iterators into one
#
# functions:
# * bidirectional
class Concat < Iterator::Base
	def initialize(*iterators)
		@iterators = iterators
		first
	end
	def skip_next
		while @iterators[@position].is_done?
			@position += 1
			return if @position >= @iterators.size 
			@iterators[@position].first
		end
	end
	def first
		@position = 0
		@iterators[@position].first
		skip_next
	end
	def next
		@iterators[@position].next  
		skip_next
	end
	def skip_prev
		while @iterators[@position].is_done?
			@position -= 1
			return if @position < 0
			@iterators[@position].last
		end
	end
	def last
		@position = @iterators.size-1
		@iterators[@position].last
		skip_prev
	end
	def prev
		@iterators[@position].prev  
		skip_prev
	end
	def is_done?
		(@position < 0) or (@position >= @iterators.size)
	end
	def current
		@iterators[@position].current
	end
	def current=(value)
		@iterators[@position].current = value
	end
end

# purpose:
# converts #each intern-iterators into extern-iterators
#
# functions:
# * forward only. Its not possible to reverse the iterator!
#
# example:
# iterator = Iterator::Continuation.new("test", :each_byte)
class Continuation < Iterator::Base
	def initialize(instance, symbol)
		@instance = instance
		@symbol = symbol
		first
	end
	def first
		@value = nil
		@resume_where = false
		@return_where = Proc.new{}
		@instance.method(@symbol).call {|i|
			@value = i
			callcc{|@resume_where|
				@return_where.call
				return
			}
		}
		@resume_where = false
		@return_where.call
	end
	def next
		callcc{|@return_where| @resume_where.call }
	end
	def is_done?
		@resume_where == false
	end
	def current 
		@value
	end
end

end # module Iterator

class Array
	def create_iterator
		Iterator::Collection.new(self)
	end
end
