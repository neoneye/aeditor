require 'abstract_syntax'

# purpose:
# translate regex-string into abstract-syntax-tree
class Parser
	include RegexFactory
	def initialize(regex)
		@input = regex
		@index = 0         # position in @input string
		@sequence = []     # current sequence (except last element)
		@current = nil     # last element in current sequence
		@alternations = [] # alternations to choose among
		@stack = []        # used for nested parentesis 
		while @index < @input.size
			res, skip = parse(@input[@index])
			flush
			@current = res
			@index += 1 + skip
		end
		unless @stack.empty?
			raise "missing close parentesis"
		end
		@expression = flush_alternations
	end
	attr_reader :input, :expression
private
	def flush
		return unless @current
		@sequence << @current
		@current = nil
	end
	def mk_expr
		flush
		return @sequence[0] if @sequence.size == 1
		mk_sequence(*@sequence)
	end
	def flush_alternations
		expr = mk_expr
		return expr if @alternations.empty?
		alt = @alternations + [expr]
		@alternation = []
		@sequence = []
		@current = nil
		mk_alternation(*alt)
	end
	def parse(symbol)
		res = mk_letter(symbol)
		skip = 0
		case symbol
		when '{' # repeat range (lazy/greedy)
			min_s = ""
			i = 1
			s = ""
			loop do 
				if @index+i >= @input.size
					#raise "range: premature end of string" 
					return [res, skip]
				end
				s = @input[@index+i]
				break if (s < '0') or (s > '9')
				min_s += s
				i += 1
			end
			if min_s == ""
				#raise "range: no minimum value specified" 
				return [res, skip]
			end
			min = min_s.to_i
			max = min
			if s == '}'
				# nothing
			elsif s != ','
				#raise "range: expected either '}' or ','"
				return [res, skip]
			else
				i += 1
				max_s = ""
				loop do 
					if @index+i >= @input.size
						#raise "range: premature end of string" 
						return [res, skip]
					end
					s = @input[@index+i]
					break if (s < '0') or (s > '9')
					max_s += s
					i += 1
				end
				if s != "}"
					#raise "range: expected '}'" 
					return [res, skip]
				end
				if max_s == ""
					max = -1
				else
					max = max_s.to_i
					raise "range: expected (min <= max), but got (min > max)" if min > max
				end
			end
			lazy = false
			if @index+1 < @input.size
				if @input[@index+i+1] == '?'
					lazy = true 
					i += 1
				end
			end
			skip = i
			res = mk_repeat(@current, min, max, lazy)
			@current = nil
		when '+', '*'  # repeat (lazy/greedy)
			lazy = false
			if @index+1 < @input.size
				if @input[@index+1] == '?'
					lazy = true 
					skip = 1
				end
			end
			n = (symbol == '*') ? 0 : 1
			res = mk_repeat(@current, n, -1, lazy)
			@current = nil
		when '.'  # any
			res = mk_wild
		when '('  # parantesis-begin
			flush
			@stack << [@sequence, @alternations]
			@sequence = []
			@current = nil
			@alternations = []
			res = nil
		when ')'  # parantesis-end
			if @stack.empty?
				raise "missing open parentesis"
			end
			res = mk_group(flush_alternations)
			@sequence, @alternations = @stack.pop
			@current = nil
		when '|'  # alternation
			@alternations << mk_expr
			@sequence = []
			@current = nil
			res = nil
		when '\\' # escape
			symbol1 = @input[@index+1]
			if @index+1 >= @input.size
				raise "nothing to escape"
			end
			case symbol1
			when '1'..'9' # backreference
				res = mk_backref(symbol1.to_i)
				skip = 1
			else # escaped symbol
				res = mk_letter(symbol1)
				skip = 1
			end
		end
		[res, skip]
	end
end

if $0 == __FILE__
	p Parser.new("0(a|b|(xy)+)*?1".split(//)).expression
end
