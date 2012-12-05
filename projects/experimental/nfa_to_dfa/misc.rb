class Object
	def deep_clone
		Marshal::load(Marshal.dump(self))
	end
	alias with instance_eval
end

module Kernel
	def with(object, &block)
		object.instance_eval(&block)
	end
end

# purpose:
# make it easy to enable/disable debugging
#
# if @debug == nil then  output are disabled
# if @debug != nil then  output are enabled
module Debuggable
	def print(*args)
		return unless @debug
		super(*args)
	end
	def puts(*args)
		return unless @debug
		super(*args)
	end
	def p(*args)
		return unless @debug
		super(*args)
	end
end
