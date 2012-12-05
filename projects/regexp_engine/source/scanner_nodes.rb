require 'regexp/misc'

class Mismatch < StandardError; end

class Context
	class IndexBase
		def close; end
	end
	def initialize(input_iterator, captures, indexes, found)
		@input = input_iterator
		@captures = captures
		@indexes = indexes 
		@found = found
	end
	attr_reader :input, :captures, :found, :indexes
	def clone
		self.class.new(
			@input.clone, 
			@captures.map{|i| i ? i.clone : nil },
			@indexes.map{|i| i.clone },
			@found ? @found.clone : nil
		)
	end
	def close
		@input.close
		@captures.map!{|c| c.close if c; nil}
		@found.close if @found
		@found = nil
		@indexes.each{|i| i.close}
		@indexes = []
	end
	def set_captures(captures)
		@captures.map!{|c| c.close if c; nil} 
		@captures = captures
	end
	def current
		@input.current
	end
	def input_next(&block)
		old = @input.clone
		@input.next
		block.call
	ensure
		@input.close
		@input = old
	end
	def set_input(iterator, &block)
		old = @input
		@input = iterator
		block.call
	ensure
		@input.close
		@input = old
	end
	def input_backward(&block)
		return block.call if @input.i.kind_of?(Iterator::Reverse)
		# reverse direction by taking the iterator behind the Reverse proxy
		set_input(@input.reverse) { block.call }
	end
	def input_forward(&block)
		return block.call unless @input.i.kind_of?(Iterator::Reverse)
		# reverse direction by taking the iterator behind the Reverse proxy
		set_input(@input.reverse) { block.call }
	end
	def push(index, &block)
		raise TypeError unless index.kind_of?(IndexBase)
		@indexes.push(index)
		retval = nil
		begin
			retval = block.call(index)
		ensure
			@indexes.pop.close
		end
		retval
	end
	def capture_input(captureid, &block) 
		old = @captures[captureid]
		# TODO: make this nicer
		i = @input.i.kind_of?(Iterator::Reverse) ?  @input.i.i : @input
		@captures[captureid] = i.clone
		retval = nil
		begin
			retval = block.call
		ensure
			@captures[captureid].close
			@captures[captureid] = old
		end
		retval
	end
	def set_found
		@found.close if @found
		@found = nil
		@found = self.clone
	end
	def get_found  
		f = @found
		@found = nil
		f  # transfer ownership of found to caller
	end
	def raise_mismatch(message)
		#puts(@indexes.inspect.ljust(30) + message)
		raise Mismatch, message
	end
end # class Context

class Root
	def initialize(node, number_of_captures, parser=nil)
		@node = node
		@number_of_captures = number_of_captures
		@parser = parser || "empty-tree"
	end 
	attr_reader :node, :number_of_captures, :parser
	def self.compile(regexp_string)
		Parser2Scanner.convert(Parser.compile(regexp_string))
	end
	def match(context)
		@node.match(context)
	end
	def ==(other)
		(self.class == other.class) and
		(@node == other.node) and
		(@number_of_captures == other.number_of_captures)
	end
	def mk_initial_context(input)
		Context.new(
			input, 
			[nil] * @number_of_captures, 
			[],
			nil 
		)
	end
end # class Root

module ScannerHierarchy
	class Base
		def match(context)
			raise "not implemented by derived class (#{self.class})"
		end
	end

	# match inside set
	class Inside < Base
		def initialize(succ, set)
			@succ = succ
			@set = set
			super()
		end
		attr_reader :succ, :set
		def ==(other)
			(self.class == other.class) and
			(@set == other.set) and
			(@succ == other.succ)
		end
		def check_not_endofinput(context)
			return if context.input.has_next?
			context.raise_mismatch("(Inside) end of input")
		end
		def check_member_of_set(context)
			symbol = context.current
			return if @set.member?(symbol)
			context.raise_mismatch(
				"(Inside) symbol #{symbol.inspect} is not in set #{@set}")
		end
		def match(context)
			check_not_endofinput(context)
			check_member_of_set(context)
			context.input_next { @succ.match(context) }
		end
	end

	# match outside set
	class Outside < Base
		def initialize(succ, set)
			@succ = succ
			@set = set
			super()
		end
		attr_reader :succ, :set
		def ==(other)
			(self.class == other.class) and
			(@set == other.set) and
			(@succ == other.succ)
		end
		def check_not_endofinput(context)
			return if context.input.has_next?
			context.raise_mismatch("(Outside) end of input")
		end
		def check_not_member_of_set(context)
			symbol = context.current
			return unless @set.member?(symbol)
			context.raise_mismatch(
				"(Outside) symbol #{symbol.inspect} is member of set #{@set}")
		end
		def match(context)
			check_not_endofinput(context)
			check_not_member_of_set(context)
			context.input_next { @succ.match(context) }
		end
	end

	class Backreference < Base
		include StringHelper
		def initialize(succ, register, ignorecase)
			@succ = succ
			@register = register
			@ignorecase = ignorecase
			super()
		end
		attr_reader :succ, :register, :ignorecase
		def ==(other)
			(self.class == other.class) and
			(@register == other.register) and
			(@ignorecase == other.ignorecase) and
			(@succ == other.succ)
		end
		def check_equal(context, a1, a2, b1)
			until a1 >= a2
				unless b1.has_next?
					#puts "#{@input.position} mismatch (EndOfInput)"
					context.raise_mismatch("Backref expected text, but got end of input")
				end
				# ignorecase of a backreference, absurd!
				syms = [a1.current]
				if @ignorecase
					syms += syms.map{|i|byte_swapcase(i)}
				end
				unless syms.include?(b1.current)
					#puts "#{@input.position} mismatch (Backref)"
					context.raise_mismatch("Backref doesn't match")
				end
				a1.next
				b1.next
			end
		end
		def match(context)
			ibegin = context.captures[@register*2]
			context.raise_mismatch("capture is nil") unless ibegin
			iend = context.captures[(@register*2)+1]
			context.raise_mismatch("capture is nil") unless iend
			iterator_backref = ibegin.clone
			iterator_input = context.input.clone
			input = iterator_input
			begin
				check_equal(context, iterator_backref, iend, iterator_input)
				iterator_input = nil  # don't close.. we want to use the input
			ensure
				iterator_backref.close
				iterator_input.close if iterator_input
			end
			context.set_input(input) do
				@succ.match(context)
			end
		end
	end

	# purpose:
	# by invoking #begin_match, the succ node can obtain a slot when
	# its being executed for the first time.
	class BeginMatch < Base
		def initialize(succ)
			raise TypeError unless succ.respond_to?(:begin_match)
			@succ = succ
			super()
		end
		attr_reader :succ
		def ==(other)
			(self.class == other.class) and
			(@succ == other.succ)
		end
		def match(context)
			@succ.begin_match(context)
		end
	end

	# purpose:
	# prevent endless loop from occuring in repeats/lookahead/..
	class EndPattern < Base
		def initialize(parent_node)
			@node = parent_node
		end
		attr_reader :node
		def inspect
			# by overloading inspect we can break the recursion.
			"EndPattern"
		end
		def ==(other)
			# the structure is recursive and the 'repeatnode' points
			# back at Repeat. Comparing may cause endless loops.
			# so we ignore comparing @repeatnode
			(self.class == other.class) 
		end
		def match(context)
			@node.end_match(context)
		end
	end

	class RepeatBase < Base
		class Index < Context::IndexBase
			def initialize(count=nil, stack=nil)
				@count = count || 0
				@stack = stack || []
				super()
			end
			attr_reader :count, :stack
			def ==(other)
				(self.class == other.class) and
				(count == other.count) and
				(stack == other.stack)
			end
			#def clone  #  TODO: seems not to make a difference ?
			#	self.class.new(
			#		@count, 
			#		@stack.map{|i| i.clone}
			#	)
			#end
			def push_input(input, &block)
				@stack.push(input)
				retval = nil
				begin
					retval = block.call
				ensure
					@stack.pop.close
				end
				retval
			end
			def increment(&block)
				old = @count
				@count += 1
				retval = nil
				begin
					retval = block.call
				ensure
					@count = old
				end
				retval
			end
		end
		def initialize(succ, pattern, min, max)
			@succ = succ
			@pattern = pattern
			@min = min
			@max = max
			@index = nil
			super()
		end
		attr_reader :succ, :pattern, :min, :max, :index
		def set_pattern(pattern)
			@pattern = pattern
		end
		def ==(other)
			# the structure is recursive and the 'pattern' points
			# back at Repeat. Comparing may cause endless loops.
			(self.class == other.class) and
			(@pattern == other.pattern) and
			(@succ == other.succ) and
			(@min == other.min) and
			(@max == other.max) and
			(@index == other.index)
		end
		def begin_match(context)
			old = @index
			@index = Index.new
			retval = nil
			begin
				retval = context.push(@index) do
					match(context)
				end
			ensure
				@index.close if @index
				@index = old
			end
			retval
		end
		def end_match(context)
			raise "derived class (#{self.class}) must overload #end_match"
		end
		def match_pattern(context)
			@index.push_input(context.input.clone) do
				@index.increment do
					@pattern.match(context) 
				end
			end
		end
		def match_min(context)
			match_pattern(context)
		end
		def match_max(context)
			@succ.match(context)
		end
		def match_range(context)
			raise "derived class (#{self.class}) must overload #match_range"
		end
		def match(context)
			n = @index.count
			if @max != -1 and n > @max
				raise "index.n = #{n}, was out of range #{@min}..#{max}"
			end
			if n == @max
				return match_max(context)
			end
			if n < @min
				return match_min(context)
			end
			match_range(context)
		end
	end

	# constraints:
	# * @pattern must be terminated with a EndPattern node
	class RepeatLazy < RepeatBase
		def end_match(context)
			# this method is invoked from EndPattern
			# raises mismatch to prevent endless loop via epsilon transistions.
			if @index.count > @min
				if @max == -1 and @index.stack[-1] == context.input
					context.raise_mismatch("endless loop")
				end
			end
			match(context)
		end
		def match_range(context)
			@succ.match(context)
		rescue Mismatch
			match_pattern(context)
		end
	end

	# constraints:
	# * @pattern must be terminated with a EndPattern node
	class RepeatGreedy < RepeatBase
		def end_match(context)
			# this method is invoked from EndPattern
			# raises mismatch to prevent endless loop via epsilon transistions.
			if @index.count != 1 and @index.count > @min
				if @max == -1 and @index.stack[-1] == context.input
					context.raise_mismatch("endless loop")
				end
			end
			match(context)
		end
		def match_range(context)
			match_pattern(context)
		rescue Mismatch
			@succ.match(context)
		end
	end

	class Alternation < Base
		def initialize(*patterns)
			@patterns = patterns
			super()
		end
		attr_reader :patterns
		def ==(other)
			(self.class == other.class) and
			(@patterns == other.patterns)
		end
		def match(context)
			@patterns.each do |pattern|
				begin
					return pattern.match(context)
				rescue Mismatch
				end
			end
			raise Mismatch, "exhausted alternation"
		end
	end

	# constraints:
	# * must only remember the forward iterators. In case the
	#   input is reversed (lookbehind).. then we have to convert
	#   it back into a forward iterator. Backreferences expects
	#   only forward iterators. Backwards iterators not allowed.
	class Capture < Base
		def initialize(succ, register)
			@succ = succ
			@register = register
			super()
		end
		attr_reader :succ, :register
		def ==(other)
			(self.class == other.class) and
			(@register == other.register) and
			(@succ == other.succ)
		end
		def match(context)
			context.capture_input(@register) do 
				@succ.match(context)
			end
		end
	end

	class LookaheadPositive < Base
		class Index < Context::IndexBase
			def initialize(input)
				@input = input
				super()
			end
			attr_reader :input
			def ==(other)
				(self.class == other.class) and
				(input == other.input)
			end
			def close
				@input.close if @input
				@input = nil
			end
		end
		def initialize(succ, pattern)
			@succ = succ
			@pattern = pattern
			@index = nil
			super()
		end
		attr_reader :succ, :pattern
		def set_pattern(pattern)
			@pattern = pattern
		end
		def end_match(context)
			# this method is invoked from EndPattern
			input = @index.input.clone
			context.set_input(input) do
				@succ.match(context)
			end
		end
		def begin_match(context)
			old = @index
			@index = Index.new(context.input.clone)
			retval = nil
			begin
				retval = match(context)
			ensure
				@index.close
				@index = old
			end
			retval
		end
		def match(context)
			context.input_forward { @pattern.match(context) }
		end
	end

	class LookaheadNegative < Base
		class LookaheadMismatch < StandardError
			def initialize(captures)
				@captures = captures
				super()
			end
			attr_reader :captures
		end
		def initialize(succ, pattern)
			@succ = succ
			@pattern = pattern
			super()
		end
		attr_reader :succ, :pattern
		def set_pattern(pattern)
			@pattern = pattern
		end
		def end_match(context)
			# this method is invoked from EndPattern
			raise LookaheadMismatch, context.captures.map{|i| i ? i.clone : nil}
		end
		def match(context)
			begin
				context.input_forward { @pattern.match(context) }
				raise "should not happen"
			rescue Mismatch
				# believe it or not, we got a match
				# TODO: context.raise_mismatch must take snapshot
				# and propagate the capture-snapshot back to here so
				# it can be installed..  otherwise captures inside 
				# negative-lookahead/behind will be nil.
			rescue LookaheadMismatch => e
				context.set_captures(e.captures)
				context.raise_mismatch("negative lookahead mismatch")
			end
			@succ.match(context)
		end
	end

	class LookbehindPositive < Base
		class Index < Context::IndexBase
			def initialize(input)
				@input = input
				super()
			end
			attr_reader :input
			def ==(other)
				(self.class == other.class) and
				(input == other.input)
			end
			def close
				@input.close if @input
				@input = nil
			end
		end
		def initialize(succ, pattern)
			@succ = succ
			@pattern = pattern
			@index = nil
			super()
		end
		attr_reader :succ, :pattern
		def set_pattern(pattern)
			@pattern = pattern
		end
		def end_match(context)
			# this method is invoked from EndPattern
			context.set_input(@index.input.clone) do
				@succ.match(context)
			end
		end
		def begin_match(context)
			old = @index
			@index = Index.new(context.input.clone)
			retval = nil
			begin
				retval = match(context)
			ensure
				@index.close
				@index = old
				$dbg = false
			end
			retval
		end
		def match(context)
			context.input_backward do
				@pattern.match(context)
			end
		end
	end

	class LookbehindNegative < Base
		class LookbehindMismatch < StandardError; end
		def initialize(succ, pattern)
			@succ = succ
			@pattern = pattern
			super()
		end
		attr_reader :succ, :pattern
		def set_pattern(pattern)
			@pattern = pattern
		end
		def end_match(context)
			# this method is invoked from EndPattern
			raise LookbehindMismatch, "negative lookbehind does not match"
		end
		def match(context)
			begin
				context.input_backward { @pattern.match(context) }
				raise "should not happen"
			rescue Mismatch
				# believe it or not, we got a match
			rescue LookbehindMismatch
				context.raise_mismatch("negative lookbehind mismatch")
			end
			@succ.match(context)
		end
	end

	class AtomicGroup < Base
		class AtomicGroupMismatch < StandardError; end
		def initialize(succ, pattern)
			@succ = succ
			@pattern = pattern
			super()
		end
		attr_reader :succ, :pattern
		def set_pattern(pattern)
			@pattern = pattern
		end
		def end_match(context)
			@succ.match(context)
		rescue Mismatch
			raise AtomicGroupMismatch
		end
		def match(context)
			@pattern.match(context)
		rescue AtomicGroupMismatch
			context.raise_mismatch("atom group")
		end
	end

	class Last < Base
		def ==(other)
			(self.class == other.class)
		end
		def match(context)
			context.set_found
		end
	end

	class Anchor < Base
		def initialize(succ, anchor_type)
			@succ = succ
			@anchor_type = anchor_type
			super()
		end
		attr_reader :succ, :anchor_type
		def ==(other)
			(self.class == other.class) and
			(@anchor_type == other.anchor_type) and
			(@succ == other.succ)
		end
		def match(context)
			case @anchor_type
			when :string_begin
				if context.input.last_value != nil
					context.raise_mismatch("StringBegin expected, but got no beginofinput")
				end 
			when :string_end
				if context.input.has_next?
					context.raise_mismatch("StringEnd expected, but got no endofinput")
				end
			when :string_end2
				if context.input.has_next?
					if context.input.current != SymbolNames::NEWLINE
						context.raise_mismatch("StringEnd2 expected, but got no newline")
					end
					begin
						tmp = context.input.clone.next
						if tmp.has_next?
							context.raise_mismatch("StringEnd2 expected, but got no endofinput")
						end
					ensure
						tmp.close
					end
				end
			when :line_begin
				if context.input.last_value != nil and 
					context.input.last_value != SymbolNames::NEWLINE
					context.raise_mismatch("LineBegin expected, but got no newline")
				end
			when :line_end
				if context.input.has_next? and 
					context.input.current != SymbolNames::NEWLINE
					context.raise_mismatch("LineEnd expected, but got no newline")
				end
			when :word_boundary
				if not context.input.is_boundary?
					context.raise_mismatch("WordBoundary expected, but got none")
				end
			when :nonword_boundary
				if context.input.is_boundary?
					context.raise_mismatch("NonwordBoundary expected, but got none")
				end
			else
				raise "unknown anchor type=#{@anchor_type}"
			end
			@succ.match(context)
		end
	end
end # module ScannerHierarchy

module ScannerFactory
	include ScannerHierarchy
	def mk_last
		Last.new
	end
	def mk_slot(node) 
		BeginMatch.new(node)
	end
	def mk_inside2(node, set)
		Inside.new(node, set)
	end
	def mk_inside(node, *symbols)
		set = RangeSet.new(symbols)
		Inside.new(node, set)
	end
	alias mk_match mk_inside
	def mk_outside2(node, set)
		Outside.new(node, set)
	end
	def mk_outside(node, *symbols)
		set = RangeSet.new(symbols)
		Outside.new(node, set)
	end
	def mk_dot(node)
		mk_outside(node, SymbolNames::NEWLINE)
	end
	alias mk_wild mk_dot
	def mk_alt(*nodes)
		Alternation.new(*nodes)
	end
	def mk_repeat_greedy(node, pattern_node, min, max)
		RepeatGreedy.new(node, pattern_node, min, max)
	end
	def mk_repeat_lazy(node, pattern_node, min, max)
		RepeatLazy.new(node, pattern_node, min, max)
	end
	def mk_pattern_end(parent_node)
		EndPattern.new(parent_node)
	end
	def mk_backref(node, register, ignorecase=false)
		Backreference.new(node, register, ignorecase)
	end
	def mk_capture(node, register)
		Capture.new(node, register)
	end
	def mk_begin_line(node)
		Anchor.new(node, :line_begin)
	end
	def mk_end_line(node)
		Anchor.new(node, :line_end)
	end
	def mk_nonword_boundary(node)
		Anchor.new(node, :nonword_boundary)
	end
	def mk_word_boundary(node)
		Anchor.new(node, :word_boundary)
	end
	def mk_begin_string(node)
		Anchor.new(node, :string_begin)
	end
	def mk_end_string(node)
		Anchor.new(node, :string_end)
	end
	def mk_end_string2(node)
		Anchor.new(node, :string_end2)
	end
	def mk_lookahead_positive(succ, pattern)
		LookaheadPositive.new(succ, pattern)
	end
	def mk_lookahead_negative(succ, pattern)
		LookaheadNegative.new(succ, pattern)
	end
	def mk_lookbehind_positive(succ, pattern)
		LookbehindPositive.new(succ, pattern)
	end
	def mk_lookbehind_negative(succ, pattern)
		LookbehindNegative.new(succ, pattern)
	end
	def mk_atomic_group(succ, pattern)
		AtomicGroup.new(succ, pattern)
	end
end # module ScannerFactory


# purpose:
# transform tree. So that each node, knows the successing node.
#
class Parser2Scanner
	include ScannerFactory
	def initialize
		@last = ScannerHierarchy::Last.new
		@succ = @last  
		@traverse_backwards = true
	end
	def self.convert(parser_ast)  
		# surround with capture 0/1                   
		ast = RegexAbstractSyntax::Group.mk_group(parser_ast) 
		# assign register id's to be used for captures
		v = AssignRegistersVisitor.new
		ast.accept(v)
		number_of_captures = v.register * 2
		# convert from Parser 2 Scanner
		ast_top_node = ast.accept(self.new)
		Root.new(ast_top_node, number_of_captures, parser_ast)
	end
	def dir_backwards(&block)
		old, @traverse_backwards = @traverse_backwards, true
		block.call
		@traverse_backwards = old
	end
	def dir_forward(&block)
		old, @traverse_backwards = @traverse_backwards, false
		block.call
		@traverse_backwards = old
	end
	def visit_literal(i) 
		mk_inside2(@succ, i.set)
	end
	def visit_wildcard(i) 
		mk_outside2(@succ, i.set)
	end
	def visit_backreference(i)
		mk_backref(@succ, i.number, i.ignorecase)
	end
	def visit_sequence(i) 
		if @traverse_backwards
			# this is used primary by lookahead.  and sometimes by sequence.
			i.exprs.reverse_each{|child| @succ = child.accept(self) }
		else
			# this is used primary by lookbehind. and sometimes by sequence.
			i.exprs.each{|child| @succ = child.accept(self) }
		end
		@succ
	end
	def visit_alternation(node_alt) 
		number_of_nodes = node_alt.exprs.size
		if number_of_nodes < 2
			raise ArgumentError, "alternation must contain least 2 nodes, " +
				"but contained #{number_of_nodes}"
		end
		succ = @succ
		nodes = node_alt.exprs.map do |expr|
			@succ = succ
			expr.accept(self)
		end
		mk_alt(*nodes)
	end
	def visit_repeat(i)
		rep = if i.lazy
			mk_repeat_lazy(@succ, nil, i.min, i.max)
		else
			mk_repeat_greedy(@succ, nil, i.min, i.max)
		end
		@succ = mk_pattern_end(rep)
		pattern = i.expr.accept(self)
		rep.set_pattern(pattern)
		mk_slot(rep)
	end
	def visit_group(i) 
		case i.group_type
		when RegexAbstractSyntax::Group::PURE
			return i.expr.accept(self)
		when RegexAbstractSyntax::Group::NORMAL
			n_end = @traverse_backwards ? 1 : 0
			n_begin = @traverse_backwards ? 0 : 1
			@succ = mk_capture(@succ, i.register*2+n_end) # end
			@succ = i.expr.accept(self)
			return mk_capture(@succ, i.register*2+n_begin) # begin
		when RegexAbstractSyntax::Group::ATOMIC
			atom = mk_atomic_group(@succ, nil)
			@succ = mk_pattern_end(atom)
			pattern = i.expr.accept(self)
			atom.set_pattern(pattern)
			return atom
		when RegexAbstractSyntax::Group::LOOKAHEAD_POSITIVE
			look = mk_lookahead_positive(@succ, nil)
			@succ = mk_pattern_end(look)
			dir_backwards do
				look.set_pattern(i.expr.accept(self))
			end
			return mk_slot(look)
		when RegexAbstractSyntax::Group::LOOKAHEAD_NEGATIVE
			look = mk_lookahead_negative(@succ, nil)
			@succ = mk_pattern_end(look)
			dir_backwards do
				look.set_pattern(i.expr.accept(self))
			end
			return look 
		when RegexAbstractSyntax::Group::LOOKBEHIND_POSITIVE
			look = mk_lookbehind_positive(@succ, nil)
			@succ = mk_pattern_end(look)
			dir_forward do
				look.set_pattern(i.expr.accept(self))
			end
			return mk_slot(look)
		when RegexAbstractSyntax::Group::LOOKBEHIND_NEGATIVE
			look = mk_lookbehind_negative(@succ, nil)
			@succ = mk_pattern_end(look)
			dir_forward do
				look.set_pattern(i.expr.accept(self))
			end
			return look 
		end
		raise "don't know how to convert group_type"
	end
	def visit_anchor(i) 
		ScannerHierarchy::Anchor.new(@succ, i.anchor_type)
	end
end # class Parser2Scanner
