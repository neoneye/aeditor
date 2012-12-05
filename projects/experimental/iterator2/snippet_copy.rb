require 'iterator'


class Object
	def self.copy(ibegin, iend, result)
		until ibegin.is_done? or ibegin.position >= iend.position
			result << ibegin.current
			ibegin.next
		end
		result
	end
	def self.copy_n(ibegin, count, result)
		until ibegin.is_done? or count <= 0
			result << ibegin.current
			ibegin.next
			count -= 1
		end
		result
	end
	def self.copy_backward(ibegin, iend, result)
		until iend.is_done? or iend.position <= ibegin.position
			result << iend.current
			iend.prev
		end
		result
	end
end

class Array
	def self.copy(ibegin, iend)
		super(ibegin, iend, [])
	end
	def self.copy_n(ibegin, count)
		super(ibegin, count, [])
	end
	def self.copy_backward(ibegin, iend)
		super(ibegin, iend, [])
	end
end

#i1 = Iterator::Continuation.new("hello world", :each_byte)
i1 = "hello world".split(//).create_iterator
i1.next
i1.next
i1.next
i2 = i1.clone
i2.next
i2.next
i2.next
i2.next

p Array.copy(i1.clone, i2.clone)
p Array.copy_n(i1.clone, 2)
p Array.copy_backward(i1.clone, i2.clone)
