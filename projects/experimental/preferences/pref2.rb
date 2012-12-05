class Base
	@@defaults = Hash.new {|h, k| h[k] = Hash.new }
	def initialize
		@options = {}
	end
	def self.defaults
		@@defaults
	end
	def self.def_option(name, default_value)
		@@defaults[self][name] = default_value
		class_eval <<-CODE
			def set_#{name}(value)
				#puts "setting #{name} to \#{value}"
				@options[#{name.inspect}] = value
			end
			def get_#{name}
				@options[#{name.inspect}] || 
					@@defaults[self.class][#{name.inspect}]
			end
		CODE
		alias_method("#{name}=", "set_#{name}")
		alias_method("#{name}", "get_#{name}")
	end
	def unset(name)
		@options.delete(name)
	end
	def result
		r = {}
		default_values = @@defaults[self.class]
		default_values.each do |key, val|
			r[key] = @options[key] || default_values[key]
		end
		r
	end
end

class Mode < Base
	def_option(:lexer, nil)
	def_option(:tabsize, 8)
	def_option(:autoindent, true)
end

class Theme < Base
	def_option(:bg_color, :red)
end

p Base.defaults

i = Mode.new
i.set_lexer :ruby
i.set_tabsize 2
p i.tabsize
p i.result
i.tabsize = 3
p i.tabsize
p i.result
p i.get_lexer
i.unset :lexer
p i.get_tabsize
i.unset :tabsize
p i.get_tabsize
p i.get_lexer
p i.result
