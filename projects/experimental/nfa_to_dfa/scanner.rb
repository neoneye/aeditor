require 'misc'

module ScannerHierarchy
	class Base
	end

	class Match < Base
		# must be initialized with a node in the abstract
		# syntax tree (AST)
		def initialize(ast_node)
			@node = ast_node
		end
		attr_reader :node
		def accept(visitor); visitor.visit_match self end
		def match(other); node.match(other) end
		def pretty; node.match_inspect end
	end

	class Composite < Base
		# true = open
		# false = close
		def initialize(open_close)
			@open_close = open_close
		end
		attr_reader :open_close
	end

	class Repeat < Composite
		def accept(visitor); visitor.visit_repeat self end
		def pretty; open_close ? "REP" : "/REP" end
	end

	class Alternation < Composite
		def accept(visitor); visitor.visit_alternation self end
		def pretty; open_close ? "ALT" : "/ALT" end
	end

	# encapsulation of pattern(s) in an alternation
	class Pattern < Composite
		def accept(visitor); visitor.visit_pattern self end
		def pretty; open_close ? "PAT" : "/PAT" end
	end

	class Group < Composite
		def initialize(*args)
			super(*args)
			@register = nil
		end
		def accept(visitor); visitor.visit_group self end
		attr_accessor :register
		def pretty; open_close ? "GRP" : "/GRP" end
	end
end # module ScannerHierarchy

# purpose:
# transform tree into an onedimentional list,
# so it is easier to iterate.
#
# The same concept as XML: 
# composite's gets a open-tag + close-tag.
# leaf-nodes does'nt get anything.
#
class Abstract2ScannerVisitor  
	def initialize
		@result = []
	end
	attr_reader :result
	def leaf(i) 
		@result << ScannerHierarchy::Match.new(i)
	end
	def visit_literal(i); leaf i end
	def visit_wildcard(i); leaf i end
	def visit_backreference(i); leaf i end
	def visit_sequence(i) 
		i.exprs.each{|child| child.accept(self)}
	end
	def visit_alternation(i) 
		@result << ScannerHierarchy::Alternation.new(true)
		i.exprs.each{|child| 
			@result << ScannerHierarchy::Pattern.new(true)
			child.accept(self)
			@result << ScannerHierarchy::Pattern.new(false)
		}
		@result << ScannerHierarchy::Alternation.new(false)
	end
	def visit_repeat(i)
		@result << ScannerHierarchy::Repeat.new(true)
		i.expr.accept(self)
		@result << ScannerHierarchy::Repeat.new(false)
	end
	def visit_group(i) 
		@result << ScannerHierarchy::Group.new(true)
		i.expr.accept(self)
		@result << ScannerHierarchy::Group.new(false)
	end
end

# purpose:
# regex scanner
#
# On startup a sentinel element (position_input=0) is
# pushed on the @stack. When we later encounter a
# repeatOpen tag, we have a place where we can store
# the repeat-stack.
#
# When an AlternationOpen tag are encountered
# a [position_input, []] tupple is pushed on the
# @stack. Note: the empty array is used to keep 
# track of repeat.
#
# When a RepeatOpen tag are encountered a
# repeat-tupple is pushed on the last element in
# @stack[-1][1].push [position_input, position_regex, stop, count]
#
# When an AlternationClose tag are encountered we 
# must:  if the repeat-stack is empty, we can pop the
# element. If there are elements on the repeat-stack
# we will have to push a new alternation-element
# on the @stack.
#
# the format of a repeat-elements are:
# [position_input, position_regex, repeat-n, repeat-count]
# where 'repeat-n' are the number of times that the
# repeat-pattern is supposed to be executed.
# where 'repeat-count' are the number of times the
# repeat-pattern has been executed so far. 
# constraint:  repeat-count <= repeat-n
#
# rule: end of repeat occurs, when there is a node 
# in the repeat-pattern that mismatches.
#
class Scanner
	include Debuggable
	class Mismatch < StandardError; end
	class EndOfInput < StandardError; end
	class EndOfRegex < StandardError; end

	# purpose:
	# stack of alternations and repeats
	#
	#   |------->
	#   |--->
	#   |----------->
	#   |----->
	#
	# Alternations grows from top to bottom
	# Repeats grows from left to right.
	class Stack
		def initialize(position_input=0)
			@stack = []
			push_alternation(position_input, [])
		end
		attr_reader :stack
		def push_repeat(pos_input, pos_regex, length=0, count=0)
			@stack[-1][2] << [pos_input, pos_regex, length, count]
			self
		end
		def push_alternation(pos_input, next_pos_regex)
			@stack << [pos_input, next_pos_regex, []]
			self
		end
		def alternation_point
			@stack[-1][0]
		end
		def repeat_position
			pi, pr, len, cnt = @stack[-1][2][-1]
			[pi, pr]
		end
		def increment_repeat_length
			pi, pr, len, = @stack[-1][2][-1]
			@stack[-1][2][-1] = [pi, pr, len+1, 0]
		end
		def increment_repeat_count
			raise "repeat-stack is empty" if @stack[-1][2].empty?
			pi, pr, length, count = @stack[-1][2][-1]
			@stack[-1][2][-1] = [pi, pr, length, count+1]
		end
		def count_less_than_length?
			pi, pr, length, count = @stack[-1][2][-1]
			(count < length)
		end
		def has_repeat?
			not @stack[-1][2].empty?
		end
		# flush repeat, return next alternation
		def next_alternation!
			pi, pr_ary, rep = @stack[-1]
			raise if pr_ary.empty?
			pr = pr_ary.shift
			@stack[-1] = [pi, pr_ary, []]
			[pi, pr]
		end
		def number_of_repeat_elements
			@stack[-1][2].size
		end
		def pop_repeat
			@stack[-1][2].pop
		end
		def pop_alternation
			@stack.pop
		end
	end

	def initialize(regex, input, debug=false)
		@regex = regex
		@input = input
		@debug = debug  # puts/print does nothing
		@position_regex = 0
		@position_input = 0
		@stack = Stack.new
		@registers = init_registers
		@result = nil
	end
	attr_reader :regex, :input 
	attr_reader :position_regex, :position_input 
	attr_reader :stack
	attr_reader :registers, :result
	def position
		"I#{@position_input}_R#{@position_regex}"
	end
	def init_registers
		n = 1
		stack = []
		@regex.each{|i|
			next unless i.kind_of?(ScannerHierarchy::Group) 
			if i.open_close
				stack << n
				i.register = n
				n += 1 
			else
				i.register = stack.pop
			end
		}
		[nil] * n
	end
	def step
		if @position_regex >= @regex.size    
			# keep track of longest match so far
			# this depends on the kind of repeat
			# that we are dealing with on the stack
			# when Greedy then keep taking snapshots.
			# when Lazy then pop element.
			print "end-of-regex: old-result=#{@result.inspect}"
			@registers[0][1] = @position_input-1
			@result = @registers.deep_clone  
			puts " new-result=#{@result.inspect}"
			raise EndOfRegex unless @stack.has_repeat?

			# increment repeat-length
			@stack.increment_repeat_length
			@position_input, @position_regex = @stack.repeat_position
			puts "end-of-regex -> restart at #{position}" 
			puts "stack=#{@stack.stack.inspect}" 
		end
		if @position_input >= @input.size
			# Currently we pop a repeat element from the current repeat-stack.
			# NOTE: is this correct behavier ?
			# pop_repeat will only pop from the current alternation,
			# I wonder if pop_repeat also should consider poping from
			# the previous alternation/repeat stacks ?
			# Example: The current alternation.repeat are empty
			# should pop_repeat then look backward in the alternation
			# stack for an alternation which has a non-empty repeat-stack
			# from which it can pop ? I don't know yet ?
			if @stack.number_of_repeat_elements < 2
				# there is not enough elements
				# on the stack.. restarting is
				# not possible
				raise EndOfInput  # premature end of input
			end
			@stack.pop_repeat
			# increment repeat-length
			@stack.increment_repeat_length
			@position_input, @position_regex = @stack.repeat_position
			puts "end-of-input -> pop and restart at #{position}"
			puts "stack=#{@stack.stack.inspect}" 
		end
		begin
			@regex[@position_regex].accept(self) 
		rescue Mismatch
			print "mismatch -> "
			if @stack.has_repeat? and @stack.count_less_than_length?
				@stack.pop_repeat
				print "pop, "
			end
			if @stack.has_repeat? and not @stack.count_less_than_length?
				# repeat_length+=1; restart at repeat-point
				@stack.increment_repeat_length
				@position_input, @position_regex = @stack.repeat_position
				puts "restart at #{position}"
				puts "stack=#{@stack.stack.inspect}" 
			else
				# try next pattern in alternation
				puts "try next alternation"
				puts @stack.stack.inspect
				@position_input, @position_regex = @stack.next_alternation!
			end
		end
	end
	def execute
		@input.each_index do|i|
			@position_input = i
			begin
				s = "-"*40
				puts s + "\nattempting to match at I#{@position_input}"
				# TODO: flush @registers 
				@stack = Stack.new(i)
				@result = nil
				@position_regex = 0
				@registers[0] = [@position_input, nil]
				loop { step }
			rescue EndOfRegex, EndOfInput, Mismatch => e  
				puts "rescued #{e.inspect}"
				if @result != nil
					# nothing more to do because we have found 
					# the first left-most-longest match 
					return  
				end
			end
		end
		nil
	end
	def visit_match(r)
		i = @input[@position_input] 
		if r.match(i)
			puts "#{position} match"
			@position_input += 1
			@position_regex += 1
			return
		end
		puts "#{position} mismatch (#{r.node.match_inspect} != #{i.inspect})"
		raise Mismatch, 
			"literal: got #{i.inspect}, " + 
			"expected #{r.inspect}, " +
			"at position I#{@position_input}_R#{@position_regex}"
	end
	def visit_repeat(r)
		#raise "not implemented"
		if r.open_close
			puts "#{position} repeat-open"
			@stack.push_repeat(@position_input, @position_regex+1, 0, 0)
			# skip to RepeatClose+1
			n = 1
			while n > 0
				@position_regex += 1
				v = @regex[@position_regex]
				if v.kind_of?(ScannerHierarchy::Repeat)
					n = (v.open_close) ? (n+1) : (n-1)
				end
			end
			@position_regex += 1
		else
			print "#{position} repeat-close"
			# flush alternations until we find a repeat-stack which isn't empty
			until @stack.has_repeat? 
				@stack.pop_alternation 
			end                       
			# TODO: That repeat element we increment, most be the same
			# as the one we pushed when RepeatOpen occured.
			# for instance /x((.)*)*x/ the element doesn't have
			# to be the last element.  BTW what should happen to the
			# remaining elements ?
			@stack.increment_repeat_count
			if @stack.count_less_than_length?
				ign, @position_regex = @stack.repeat_position
			else
				@position_regex += 1
			end
			puts @stack.stack.inspect
		end
	end
	def visit_alternation(r)
		if r.open_close
			puts "#{position} AlternationOpen"
			# identify start position for each sub-pattern
			start = []
			pr = @position_regex + 1
			n = 1
			while n > 0
				pr < @regex.size
				v = @regex[pr]
				if v.kind_of?(ScannerHierarchy::Alternation)
					n = (v.open_close) ? (n+1) : (n-1)
				end
				if (n == 1) and v.kind_of?(ScannerHierarchy::Pattern) and v.open_close
					start << pr + 1
				end
				pr += 1
			end
			start.shift  # first element is not necessary
			@stack.push_alternation(@position_input, start)
			@position_regex += 1
		else
			puts "#{position} AlternationClose"
			# don't pop alternation here.. must wait until 
			# tried all possible combinations of repeat 
			@position_regex += 1
		end
	end
	def visit_pattern(r)
		if r.open_close
			puts "#{position} PatternOpen"
			#@stack.flush_repeat
			@position_input = @stack.alternation_point
			@position_regex += 1
		else
			puts "#{position} PatternClose"
			# skip until AlternationClose
			n = 1
			while n > 0
				@position_regex += 1
				v = @regex[@position_regex]
				if v.kind_of?(ScannerHierarchy::Alternation)
					n = (v.open_close) ? (n+1) : (n-1)
				end
			end
		end
	end
	def visit_group(r)
		if r.open_close
			puts "#{position} group-open"
			@registers[r.register] = [@position_input, nil]
		else
			puts "#{position} group-close"
			@registers[r.register][1] = @position_input-1
		end
		@position_regex += 1
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
