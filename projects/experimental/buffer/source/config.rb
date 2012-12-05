module Config

class Base
	MK_HASH = lambda{|h, k| h[k] = Hash.new}
	@@validate = Hash.new(&MK_HASH)
	@@default_option = Hash.new(&MK_HASH)
	def initialize(hashes=nil)
		@hashes = hashes || Hash.new(&MK_HASH)
	end
	attr_reader :hashes
	def check_valid_option(name, value)
		block = @@validate[self.class][name]
		block.call(value) if block
	end
	def check_valid_mapping(name, key, value)
		#puts "lookup name=#{name.inspect} key=#{key.inspect}"
		block = @@validate[self.class][name]
		block.call(key, value) if block
	end
	def self.def_option(name, default_value=nil, &block)
		# lets see if the default values are ok
		block.call(default_value) if block
	  # default_value are good.. we can continue
		@@default_option[self][name] = default_value
		@@validate[self][name] = block
		str_name = name.to_s
		sym_name = name.inspect
		class_eval <<-CODE
			def set_#{str_name}(value)
				check_valid_option(#{sym_name}, value)
				@hashes[:option][#{sym_name}] = value
			end
			def get_#{str_name}
				@hashes[:option][#{sym_name}] ||
					@@default_option[self.class][#{sym_name}]
			end
		CODE
		alias_method("#{str_name}=", "set_#{str_name}")
		alias_method("#{str_name}", "get_#{str_name}")
	end
	def self.def_mapping(name, &block)
		@@validate[self][name] = block
		#puts "hash: validate=#{@@validate.inspect}"
		str_name = name.to_s
		sym_name = name.inspect
		class_eval <<-CODE
			def set_#{str_name}(key, value)
				check_valid_mapping(#{sym_name}, key, value)
				@hashes[#{sym_name}][key] = value
			end
			def get_#{str_name}(key)
				@hashes[#{sym_name}][key]
			end
		CODE
		mk_hash_of(name)
	end
	def self.mk_hash_of(name)
		str_name = name.to_s
		sym_name = name.inspect
		class_eval <<-CODE
			def hash_of_#{str_name}s
				@hashes[#{sym_name}]
			end
		CODE
	end
	mk_hash_of(:option)
	def unset(name)
		@hashes[:option].delete(name)
	end
	def ==(other)
		(self.class == other.class) and
		(@hashes == other.hashes)
	end
	def initialize_copy(original)
		h = Hash.new(&MK_HASH)
		original.hashes.each do |key, val|
			h[key] = val.clone
		end
		@hashes = h
	end
	def hash_of_resulting_options
		@@default_option[self.class].merge(@hashes[:option])
	end
end # class Base

module Assertions

def check_range(expected_range, actual_integer) 
	unless actual_integer.kind_of?(Integer)
		raise TypeError, "expected Integer, " +
			"but got #{actual_integer.class}"
	end
	unless expected_range.member?(actual_integer)
		raise IndexError, "expected integer to be in range " +
			"#{expected_range}, but got #{actual_integer}"
	end
end

def check_boolean(actual_boolean)
	if actual_boolean != true and actual_boolean != false
		raise TypeError, "expected true/false, " +
			"but got #{actual_boolean.class}"
	end
end

def check_symbol_string(actual)
	unless actual.kind_of?(Symbol) or actual.kind_of?(String) 
		raise TypeError, "expected Symbol or String, but got #{actual.class}"
	end
end

def check_rgb_24bit(triplet, message)
	unless triplet.kind_of?(Array)
		raise TypeError, "expected #{message} to be " +
			"Array of integers, but got #{triplet.class}"
	end
	triplet.each do |i|
		unless i.kind_of?(Integer)
			raise TypeError, "expected #{message} to be " +
				"Array of integers, but the array " +
				"contained a #{i.class}"
		end
	end
	triplet.each do |i|
		unless (0..255).member?(i)
			raise ArgumentError, "expected #{message} to be " +
				"Array of integers in the range 0..255, " +
				"but got a value(#{i}) outside that range"
		end
	end
end

extend self

end # module Assertions

class Global < Base
	def_option(:keymap, :cua) do |value|
		raise TypeError unless value.kind_of?(Symbol)
		raise IndexError unless [:cua, :simon].member?(value)
	end
end

def global(&block)
	block.call(@global_conf)
end

class Mode < Base
	def initialize(name)
		super()
		set_name(name)
	end
	attr_reader :name
	def set_name(name)
		Assertions.check_symbol_string(name)
		@name = name.to_s
	end
	def_option(:tabsize, 8) do |value|
		Assertions.check_range(1..16, value)
	end
	def_option(:file_suffixes, []) do |value|
		raise TypeError unless value.kind_of?(Array)
		value.each do |str|
			raise TypeError unless str.kind_of?(String)
		end
	end
	def_option(:lexer) do |value|
		next if value == nil 
		raise TypeError unless value.kind_of?(Symbol)
		lexers = [:ruby, :cpp]
		raise TypeError unless lexers.member?(value)
	end
	def_option(:cursor_through_tabs, false) do |value|
		Assertions.check_boolean(value)
	end
end # class Mode

def mode(name, parent_name=nil, &block)
	m = lookup(name.to_s) 
	if parent_name and m
		raise 'the mode already exists.. you cannot inherit'
	end
	if m 
		block.call(m)
		return
	end
	if parent_name and m == nil
		pm = lookup(parent_name.to_s)
		unless pm
			raise 'no parent to derive from'
		end
		m = pm.clone
		m.set_name(name)
	else
		m = Mode.new(name) 
	end
	block.call(m)
	register(m)
end

class Theme
	include Assertions
	def initialize(name)
		set_name(name)
		@colors = {}
	end
	attr_reader :name, :colors
	def set_name(string)
		check_symbol_string(string)
		@name = string.to_s
	end
	def set_rgb_pair(string, background, foreground)
		check_symbol_string(string)
		check_rgb_24bit(background, 'background')
		check_rgb_24bit(foreground, 'foreground')
		@colors[string.to_s] = [background, foreground]
	end
	def ==(other)
		(self.class == other.class) and
		(@name == other.name) and
		(@colors == other.colors)
	end
end

def theme(name, &block)
	t = Theme.new(name)
	block.call(t)
	register_theme(t)
end

end # module Config
