class ModeInfo
	def initialize
		@tabsize = 8
	end
	def tabsize(*value)
		return @tabsize if value.empty?
		if value.size > 1
			raise ArgumentError, "expected 1 argument"
		end
		@tabsize = value[0]
	end
end

class Modes
	def register_mode(name, depends, code=nil)
		code ||= lambda{}
		depname = depends ? depends.inspect : "NONE"
		puts "adding mode name=#{name.inspect}, deps=#{depname}"
		info = ModeInfo.new
		# TODO: resolve dependencies first
		info.instance_eval(&code)
		puts "  tabsize=#{info.tabsize.inspect}"
	end
end
$modes = Modes.new

def mode(argument, &block)
	symbol = nil
	dependencies = nil
	case argument
	when Hash
		if argument.keys.size > 1
			raise ArgumentError, "max 1 key in hash"
		end
		symbol = argument.keys[0]
	when Symbol
		symbol = argument
	else
		raise TypeError, "unknown argument type #{argument.class}"
	end
	name = symbol.to_s
	if block_given?
		$modes.register_mode(name, dependencies, block)
	else
		$modes.register_mode(name, dependencies)
	end
end

def file_suffix(argument)
	puts "file suffix=#{argument.inspect}"
end

def file_match(argument)
	puts "file match=#{argument.inspect}"
end

def theme(argument)
end

require 'dotfile'
