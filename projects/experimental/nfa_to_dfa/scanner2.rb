require 'misc'

module ScannerHierarchy
	class Base
		def inspect
			pretty
		end
	end

	class Match < Base
		# must be initialized with a node in the abstract
		# syntax tree (AST)
		def initialize(ast_node, succ)
			@node = ast_node
			@succ = succ
		end
		attr_reader :node, :succ
		def accept(visitor); visitor.visit_match self end
		def match(other); node.match(other) end
		def pretty 
			node.match_inspect + " " + @succ.pretty
		end 
	end

	class Repeat < Base
		def initialize(pattern, succ)
			@pattern = pattern
			@succ = succ
		end
		attr_reader :succ, :pattern
		def accept(visitor); visitor.visit_repeat self end
		def pretty 
			"REP " + @pattern.pretty + @succ.pretty
		end
	end

	class Alternation < Base
		def initialize(patterns, succ)
			@patterns = patterns
			@succ = succ
		end
		attr_reader :succ, :patterns
		def accept(visitor); visitor.visit_alternation self end
		def pretty 
			pat = @patterns.map{|p| p.pretty}.join
			"ALT " + pat + "/ALT " + @succ.pretty
		end
	end

	class GroupOpen < Base
		def initialize(register, succ)
			@register = register
			@succ = succ
		end
		attr_reader :succ, :register
		def accept(visitor); visitor.visit_group_open self end
		def pretty 
			"GRP#{@register} " + @succ.pretty
		end
	end

	class GroupClose < Base
		def initialize(register, succ)
			@register = register
			@succ = succ
		end
		attr_reader :succ, :register
		def accept(visitor); visitor.visit_group_close self end
		def pretty 
			"/GRP#{@register} " + @succ.pretty
		end
	end

	class Nil < Base
		def accept(visitor); visitor.visit_nil self end
		def pretty; "nil " end
	end

	class RepeatEnd < Base
		def accept(visitor); visitor.visit_repeat_end self end
		def pretty; "/REP " end
	end

	class Last < Base
		def accept(visitor); visitor.visit_last self end
		def pretty; "LST" end
	end
end # module ScannerHierarchy


# purpose:
# transform tree. So that each node, knows the successing node.
#
class Abstract2ScannerVisitor  
	def initialize
		@succ = ScannerHierarchy::Last.new
		@nil = ScannerHierarchy::Nil.new
		@repeat_end = ScannerHierarchy::RepeatEnd.new
	end
	attr_reader :result
	def visit_literal(i) 
		ScannerHierarchy::Match.new(i, @succ) 
	end
	def visit_wildcard(i) 
		ScannerHierarchy::Match.new(i, @succ) 
	end
	def visit_backreference(i)
		raise "not implemented"
	end
	def visit_sequence(i) 
		i.exprs.reverse_each{|child| @succ = child.accept(self) }
		@succ
	end
	def visit_alternation(i) 
		succ = @succ
		children = i.exprs.map{|child| 
			@succ = @nil
			child.accept(self)
		}
		ScannerHierarchy::Alternation.new(children, succ)
	end
	def visit_repeat(i)
		succ = @succ
		@succ = @repeat_end
		child = i.expr.accept(self)
		ScannerHierarchy::Repeat.new(child, succ)
	end
	def visit_group(i) 
		@succ = ScannerHierarchy::GroupClose.new(i.register, @succ)
		@succ = i.expr.accept(self)
		ScannerHierarchy::GroupOpen.new(i.register, @succ)
	end
end

# purpose:
# regex scanner
#
#
# constraints: 
# * end of repeat occurs, when there is a node 
#   in the repeat-pattern that mismatches.
# 
# * it doesn't matter what state the visit_ methods
#   are in when they return. Either way return
#   occurs only on success.
#
class Scanner
	include Debuggable
	class Mismatch < StandardError; end
	class StackUnderflow < StandardError; end

	def initialize(regex, registers, input, debug=false)
		@regex = regex
		@input = input
		@debug = debug  # puts/print does nothing
		@position_input = 0
		@number_of_registers = registers
		@registers = nil
		@result = nil
		@stack = []
	end
	attr_reader :regex, :input 
	attr_reader :position_input 
	attr_reader :registers, :result
	attr_reader :number_of_registers
	def position
		"I#{@position_input}"
	end
	def execute
		@input.each_index do|i|
			@position_input = i
			begin
				s = "-"*40
				puts s + "\nattempting to match at I#{@position_input}"
				@stack = []
				@registers = [nil] * @number_of_registers
				@registers[0] = [@position_input, nil]
				@result, ignore = @regex.accept(self)
				puts "OK"
				return
			rescue StackUnderflow => e
				puts "SHOULD NOT HAPPEN: stackunderflow " + e.inspect
			rescue Mismatch => e  
				puts "rescued #{e.inspect}"
			end
		end
		nil
	end
	def visit_match(r)
		if @position_input >= @input.size
			puts "#{position} mismatch (#{r.node.match_inspect} != EndOfInput)"
			raise Mismatch, 
				"literal: got EndOfInput, " + 
				"expected #{r.inspect}, " +
				"at position #{position}"
		end
		unless r.match(i = @input[@position_input])
			puts "#{position} mismatch (#{r.node.match_inspect} != #{i.inspect})"
			raise Mismatch, 
				"literal: got #{i.inspect}, " + 
				"expected #{r.inspect}, " +
				"at position #{position}"
		end
		puts "#{position} match"
		@position_input += 1
		r.succ.accept(self)
	end
	def repeat_match_zero_times(registers, stack)
		@registers = registers.deep_clone
		@stack = stack.deep_clone
		puts "about to attempt to repeat pattern #0 times" +
			" at position #{position}"
		return ScannerHierarchy::RepeatEnd.new.accept(self)
	rescue Mismatch 
		raise "should not occur"
	end
	def repeat_match_one_time_step(r, times, registers, stack, pos)
		@stack = stack.deep_clone
		@registers = registers.deep_clone
		@position_input = pos
		puts "about to attempt to repeat pattern ##{times} times" +
			" at position #{position}"
		return r.pattern.accept(self)
	end
	def visit_repeat(r)
		puts "#{position} repeat"
		stack = @stack
		stack.push(r.succ)
		registers = @registers
		pos = @position_input

		# attempt to match zero times
		result, reps = repeat_match_zero_times(registers, stack)

		# attempt to match one or more times
		times = 1
		loop do  
			result_next, reps_next = repeat_match_one_time_step(
				r, times, registers, stack, pos)
			if reps_next == reps
				puts "NOTE: avoiding endless loop"
				return [result, reps]
			end
			result = result_next || result 
			reps = reps_next
			pos = reps[0]
			times += 1
		end
	rescue Mismatch # happened within repeat-pattern, thus stop
		puts "repeat mismatch"
		[result, reps]
	end
	def visit_alternation(r)
		puts "#{position} alternation"
		pos = @position_input
		stack = @stack
		registers = @registers
		r.patterns.each_with_index{|pattern, i|
			@position_input = pos
			begin
				@stack = stack.deep_clone
				@stack.push(r.succ)
				@registers = registers.deep_clone
				puts "pattern #{i}"
				return pattern.accept(self)
			rescue Mismatch 
				# continue to next pattern
			end
		}
		raise Mismatch
	end
	def visit_group_open(r)
		puts "#{position} group_open " + r.register.to_s
		@registers[r.register] = [@position_input, nil]
		r.succ.accept(self)
	end
	def visit_group_close(r)
		puts "#{position} group_close " + r.register.to_s
		@registers[r.register][1] = @position_input-1
		r.succ.accept(self)
	end
	def visit_nil(r) # TODO rename 'nil' into 'alternation_end'
		puts "#{position} nil"
		raise StackUnderflow if @stack.empty? 
		@stack.pop.accept(self)
	end
	def visit_repeat_end(r)
		puts "#{position} repeat_end"
		pos = @position_input
		raise StackUnderflow if @stack.empty? 
		res, reps = @stack.pop.accept(self)
		reps = reps.deep_clone
		reps.unshift(pos)
		return [res, reps]
	rescue Mismatch
		return [nil, [pos]]
	end
	def visit_last(r)
		puts "#{position} last"
		res = @registers.deep_clone
		res[0][1] = @position_input-1
		[res, []]
	end
end

if $0 == __FILE__
	require 'parser'

	# build tree
	tree = Parser.new("ax*b(c|d)e".split(//)).expression 
	p tree

	# compile tree into scanner array
	v = Abstract2ScannerVisitor.new
	tree.accept(v)
	regex = v.result

	# try to scan a text string
	s = Scanner.new(regex, "yyyaxxxbdefff".split(//))
	s.execute
	p s.result
end
