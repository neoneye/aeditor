require 'iterator'
require 'observer'

# purpose:
# a array with robust iterators
#
# functions:
# * iterators keeps pointing to the same element,
#   when doing insert/remove (primary feature).
# * normal array behavier.
#
# issues:
# * you must #detach allocated iterators.
class RobustArray
	# purpose:
	# a robust iterator, which keeps its position
	# even though you insert/remove elements.
	#
	# functions:
	# * in case of changes in the array the iterator
	#   gets notify from the parent about the change.
	# * #clone attaches the new instance to the parent.
	#
	# todo:
	# * policies for how the iterator should behave
	#   detach_on_remove, prev_on_remove, next_on_remove
	class Iterator < Iterator::Collection
		def initialize(data)
			super(data)
			@data.add_observer(self)
		end
		def close
			detach
		end
		def clone
			instance = super
			@data.add_observer(instance)
			instance
		end
		def detach
			@data.delete_observer(self)
			@data = nil
			@position = nil
		end
		def update(where, delta)
			if delta > 0
				if @position >= where
					@position += delta
				end
			elsif (where+delta..where).member?(@position)
				detach # remove ourselves from the iterator list
			elsif @position >= where
				@position += delta - 1
			end
		end
	end

	include Observable
	def initialize(ary)
		@data = ary
	end
	def to_a
		@data
	end
	def size
		@data.size
	end
	def [](index)
		@data[index]
	end
	def []=(index, value)
		@data[index] = value
	end
	def RobustArray.build_from_array(ary)
		RobustArray.new(ary)
	end
	def create_iterator
		Iterator.new(self)
	end
	def remove(range)
		res = @data.slice!(range)
		a = range.first
		b = range.last
		changed
		notify_observers(b, -(b-a))
		RobustArray.build_from_array(res)
	end
	def insert(where, data)
		ary = data.to_a
		@data[where, 0] = ary
		changed
		notify_observers(where, ary.size)
	end
end
