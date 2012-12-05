# purpose:
# shift_until/pop_until extension to Array (heavy optimized)
module ArrayMisc #[
	def shift_until(klass)
		p = -1
		detect { |x| p += 1; klass === x } or p += 1
		slice!(0, p)
	end
	def pop_until(klass)
		p = -1
		reverse.detect { |x| p += 1; klass === x } or p += 1
		slice!(-p, p)
	end
end #]

# purpose:
# shift_until/pop_until extension to Array (slow & naive)
module ArrayMisc2 #[
	def shift_until(klass)
		res = []
		until empty? or klass === first
			res << self.shift
		end
		res
	end
	def pop_until(klass)
		res = []
		until empty? or klass === last
			res.unshift(self.pop)
		end
		res
	end
end #]

module ArrayInspect #[
	def class_inspect
		klass = self.first.class
		n = 0
		result = []
		self.each do |val|
			if val.class != klass
				result << "#{klass.to_s} #{n}"
				n = 0
				klass = val.class
			end
			n += 1
		end
		result << "#{klass.to_s} #{n}" if n > 0
		result
	end
end #]

# purpose:
# zero arguments results in an exception.. therefore this wrapper
# this has been fixed in Ruby-1.8.0-preview3.
module ArrayZeroPush #[
	def new_push(*ary)
		old_push(*ary) unless ary.empty?
	end
	def self.append_features(klass)
		super
		klass.instance_eval do
			alias_method :old_push, :push
			alias_method :push, :new_push
		end
	end
end #]

# purpose:
# zero arguments results in an exception.. therefore this wrapper
# this has been fixed in Ruby-1.8.0-release1.
module ArrayZeroUnshift #[
	def new_unshift(*ary)
		old_unshift(*ary) unless ary.empty?
	end
	def self.append_features(klass)
		super
		klass.instance_eval do
			alias_method :old_unshift, :unshift
			alias_method :unshift, :new_unshift
		end
	end
end #]

class Array #[
	include ArrayMisc
	include ArrayInspect
	#include ArrayZeroPush
	#include ArrayZeroUnshift
end #]

class Object #[
	def deep_clone
		Marshal::load(Marshal.dump(self))
	end
end #]
