require 'common'
begin
	require 'test/unit/mock'
rescue LoadError
	raise "this file depends on the 'test/unit/mock' package in order to run." 
end

class TestScannerMatch < Common::TestCase  
	include ScannerFactory
	def mk_context(input, number_of_captures=0, indexes=nil)
		raise TypeError unless number_of_captures.kind_of?(Integer)
		raise TypeError unless input.kind_of?(String)
		iterator = Iterator::ProxyLast.new(input.create_iterator, nil)
		indexes ||= []
		Context.new(
			iterator, 
			[nil]*number_of_captures, 
			indexes,
			nil
		)
	end
	def mk_mock_node_match(returnval=nil, baseclass=nil)
		mock = Test::Unit::MockObject(baseclass || ScannerHierarchy::Base).new
		mock.set_return_values(
			:match => lambda{|context| 
				@match_context << context.clone
				@match_retval << returnval
				index = context.indexes[0]
				@match_index0 << (index ? index.clone : nil)
				returnval
			}
		)
		mock
	end
	def mk_mock_node_mismatch(message=nil)
		mock = Test::Unit::MockObject(ScannerHierarchy::Base).new
		mock.set_return_values(
			:match => lambda{|context| 
				@match_context << context.clone
				@match_retval << message
				index = context.indexes[0]
				@match_index0 << (index ? index.clone : nil)
				raise Mismatch, message || "mock-mismatch"
			}
		)
		mock
	end
	def setup
		@match_index0 = []
		@match_context = []
		@match_retval = []
		@node_match = mk_mock_node_match('match')
		@node_mismatch = mk_mock_node_mismatch
		@context_axx = mk_context('axx')
		@context_bxx = mk_context('bxx')
		@context_xxx = mk_context('xxx')
	end
	def generic_test_inside(*symbols)
		root = mk_match(@node_match, *symbols)
		context = @context_bxx
		input = context.input.clone
		retval = root.match(context)
		assert_equal('match', retval)
		assert_equal(1, @match_context.size)
		# check if context has been restored on exit
		assert_equal(input, context.input)
		# check that the input iterator has been advanced by one
		assert_not_equal(input, @match_context[0].input)
		input.next
		assert_equal(input, @match_context[0].input)
	end
	def generic_test_inside_fail(*symbols)
		root = mk_match(@node_match, *symbols)
		assert_raises(Mismatch) do
			root.match(@context_xxx)
		end
		assert_equal(0, @match_context.size)
	end
	def test_inside1
		generic_test_inside('b'[0])
	end
	def test_inside2
		generic_test_inside('a'[0]..'c'[0])
	end
	def test_inside3
		generic_test_inside_fail('b'[0])
	end
	def test_inside4
		generic_test_inside_fail('a'[0]..'c'[0])
	end
	def test_inside5
		context = mk_context('xx')
		root = mk_match(@node_match, 'x'[0])
		context.input_next do
			context.input_next do
				# end of input provoked
				e = assert_raises(Mismatch) do
					root.match(context)
				end
				assert_match(/end of input/, e.message)
			end
		end
	end
	def test_inside6
		# purpose: in case @succ is propagating an error, we should rollback
		node = mk_mock_node_mismatch('propagate me')
		context = mk_context('xx')
		input = context.input.clone
		root = mk_match(node, 'x'[0])
		e = assert_raises(Mismatch) do
			root.match(context)
		end
		assert_match(/propagate me/, e.message)
		# check if context has been restored on exit
		assert_equal(input, context.input)
	end
	def generic_test_outside(*symbols)
		root = mk_outside(@node_match, *symbols)
		context = @context_bxx
		input = context.input.clone
		retval = root.match(context)
		assert_equal('match', retval)
		assert_equal(1, @match_context.size)
		# check if context has been restored on exit
		assert_equal(input, context.input)
		# check that the input iterator has been advanced by one
		assert_not_equal(input, @match_context[0].input)
		input.next
		assert_equal(input, @match_context[0].input)
	end
	def generic_test_outside_fail(*symbols)
		root = mk_outside(@node_match, *symbols)
		assert_raises(Mismatch) do
			root.match(@context_xxx)
		end
		assert_equal(0, @match_context.size)
	end
	def test_outside1
		generic_test_outside('a'[0], 'c'[0])
	end
	def test_outside2
		generic_test_outside('x'[0]..'z'[0])
	end
	def test_outside3
		generic_test_outside_fail('x'[0], 'y'[0], 'z'[0])
	end
	def test_outside4
		generic_test_outside_fail('x'[0]..'z'[0])
	end
	class MockRepeatBase < ScannerHierarchy::RepeatBase
		def initialize
			@indexes = []
			@contexts = []
			super(nil, nil, 0, 0)
		end
		attr_reader :indexes, :contexts
		def match(context)
			@indexes << @index.clone
			@contexts << context.clone
			'match'
		end
	end
	def test_repeat_base1
		mock_node = MockRepeatBase.new
		context = @context_axx
		assert_nil(mock_node.index, 'unassigned')
		root = mk_slot(mock_node)
		assert_equal([], context.indexes)
		retval = root.match(context)   # obtain the first slot .. position = 0
		assert_equal('match', retval)
		assert_equal(1, mock_node.contexts.size)
		assert_equal([], context.indexes, 'afterwards restoration of context.indexes')
		index = mock_node.contexts[0].indexes[0]
		assert_kind_of(ScannerHierarchy::RepeatBase::Index, index, 'creation of index-slot')
		assert_equal(0, index.count)
		assert_equal([index], mock_node.indexes, 'assignment of index (first index)')
	end
	def test_repeat_base2
		mock_node = MockRepeatBase.new
		context = @context_axx
		assert_nil(mock_node.index, 'unassigned')
		root = mk_slot(mock_node)
		assert_equal([], context.indexes)
		i0 = nil
		i1 = nil
		context.push(ScannerHierarchy::RepeatBase::Index.new) do |index0|
			assert_equal([index0], context.indexes)
			context.push(ScannerHierarchy::RepeatBase::Index.new) do |index1|
				assert_equal([index0, index1], context.indexes)
				retval = root.match(context)   # obtain the third slot .. position = 2
				assert_equal('match', retval)
				assert_equal([index0, index1], context.indexes)
				i0 = index0
				i1 = index1
			end
		end
		assert_equal(1, mock_node.contexts.size)
		assert_equal([], context.indexes, 'afterwards restoration of context.indexes')
		expected = ScannerHierarchy::RepeatBase::Index.new
		assert_equal([i0, i1, expected], mock_node.contexts[0].indexes, 'creation of index')
		assert_equal([expected], mock_node.indexes, 'assignment of index (third index)')
	end
	def test_alternation1
		c1 = mk_mock_node_match('choice1')
		c2 = mk_mock_node_match('choice2')
		root = mk_alt(c1, c2)
		context = @context_axx
		retval = root.match(context)
		assert_equal('choice1', retval)
		assert_equal(1, @match_context.size)
		assert_equal([], @match_context[0].indexes)
	end
	def test_alternation2
		c1 = mk_mock_node_match('choice1')
		c2 = mk_mock_node_mismatch('choice2')
		root = mk_alt(c1, c2)
		context = @context_axx
		retval = root.match(context)
		assert_equal('choice1', retval)
		assert_equal(1, @match_context.size)
		assert_equal([], @match_context[0].indexes)
	end
	def test_alternation3
		c1 = mk_mock_node_mismatch('choice1')
		c2 = mk_mock_node_match('choice2')
		root = mk_alt(c1, c2)
		context = @context_axx
		retval = root.match(context)
		assert_equal('choice2', retval)
		assert_equal(2, @match_context.size)
		assert_equal([], @match_context[0].indexes)
		assert_equal([], @match_context[1].indexes)
	end
	def test_alternation4
		c1 = mk_mock_node_mismatch('choice1')
		c2 = mk_mock_node_mismatch('choice2')
		root = mk_alt(c1, c2)
		context = @context_xxx
		e = assert_raises(Mismatch) { root.match(context) }
		assert_equal(2, @match_context.size)
		assert_equal([], @match_context[0].indexes)
		assert_equal([], @match_context[1].indexes)
		assert_match(/exhausted alternation/, e.message)
	end
	def repeat_testcase(is_greedy, range, index, sfail, pfail, expected)
		setup
		succ = (sfail!=0) ? mk_mock_node_mismatch('s') : mk_mock_node_match('s')
		patt = (pfail!=0) ? mk_mock_node_mismatch('p') : mk_mock_node_match('p')
		repindex = ScannerHierarchy::RepeatBase::Index.new
		xi = index
		repindex.instance_eval '@count=xi'
		context = mk_context('abc', 0, [repindex])
		rep = if is_greedy
			mk_repeat_greedy(succ, patt, range.begin, range.end)
		else
			mk_repeat_lazy(succ, patt, range.begin, range.end)
		end
		rep.instance_eval '@index = repindex'
		root = rep
		retval = nil
		is_mismatch = false
		begin
			retval = root.match(context)
		rescue Mismatch => e
			is_mismatch = true
			retval = e.message
		end
		symbol = expected
		expected_mismatch = false
		if expected.kind_of?(Array)
			symbol = expected[0]
			expected_mismatch = true
		end
		sym2retval = {:p => %w(p), :s => %w(s), :p_s => %w(p s), :s_p => %w(s p)}
		sym2index = {:p => [index+1], :s => [index], 
			:p_s => [index+1, index], :s_p => [index, index+1]}
		[
			# check that succ/pattern got invoked in the right order
			[sym2retval[symbol], @match_retval],
			# check retval got passed around correct
			[sym2retval[symbol].last, retval],
			# check that Mismatch got raised the right places
			[expected_mismatch, is_mismatch],
			# check that index got incremented correct
			[sym2index[symbol], @match_index0.map{|i| i.count}],
			# check that index got restored on exit 
			[index, context.indexes[0].count]
		]
	end
	def pretty_repeat_expect(expect)
		symbol = expect
		suffix = ''
		if expect.kind_of?(Array)
			symbol = expect[0]
			suffix = ' mismatch'
		end
		# P = pattern,  S = succ
		sym2str = {:p => 'P', :s => 'S', :p_s => 'P, S', :s_p => 'S, P'}
		str = sym2str[symbol]
		unless str
			raise "illegal symbol #{expect.inspect}"
		end
		str + suffix
	end
	def pretty_repeat_tester(is_greedy, range, index, *expected)
		greedy_lazy = is_greedy ? 'greedy' : 'lazy'
		rows = []
		rows << 'S_P___EXPECTED  ' +
			"type=#{greedy_lazy}, range=#{range.inspect}, index=#{index}"
		0.upto(1) do |s|
			0.upto(1) do |p|
				str = pretty_repeat_expect(expected[s*2+p])
				rows << "#{s} #{p} | #{str}"
			end
		end
		rows.join("\n")
	end
	def test_pretty_repeat
		exp = <<-MSG.gsub(/^\s*/, '').chomp
		S_P___EXPECTED  type=greedy, range=5..9, index=7
		0 0 | P
		0 1 | S
		1 0 | P, S
		1 1 | S, P mismatch
		MSG
		assert_equal(exp, pretty_repeat_tester(true, 5..9, 7, :p, :s, :p_s, mismatch(:s_p)))
	end
	def repeat_tester(is_greedy, range, index, e00, e01, e10, e11)
		msg = pretty_repeat_tester(is_greedy, range, index, e00, e01, e10, e11)
		puts "\n" + msg if $DEBUG
		r = []
		r += repeat_testcase(is_greedy, range, index, 0, 0, e00)
		r += repeat_testcase(is_greedy, range, index, 0, 1, e01)
		r += repeat_testcase(is_greedy, range, index, 1, 0, e10)
		r += repeat_testcase(is_greedy, range, index, 1, 1, e11)
		exp, act = r.transpose
		assert_equal(exp, act, msg+"\nAbove diagram shows what was expected to happen.")
	end
	def assert_repeat_greedy(range, index, expect00, expect01, expect10, expect11) 
		repeat_tester(true, range, index, expect00, expect01, expect10, expect11) 
	end
	def assert_repeat_lazy(range, index, expect00, expect01, expect10, expect11) 
		repeat_tester(false, range, index, expect00, expect01, expect10, expect11) 
	end
	def mismatch(symbol)
		[symbol]
	end
	def test_repeat_lazy_min  # below range
		assert_repeat_lazy(3..5, 0, :p, mismatch(:p), :p, mismatch(:p))
	end
	def test_repeat_lazy1  # inside range 
		assert_repeat_lazy(0..1, 0, :s, :s, :s_p, mismatch(:s_p))
	end
	def test_repeat_lazy2  # inside range 
		assert_repeat_lazy(0..-1, 0, :s, :s, :s_p, mismatch(:s_p))
	end
	def test_repeat_lazy_max  # max of range
		assert_repeat_lazy(0..1, 1, :s, :s, mismatch(:s), mismatch(:s))
	end
	def test_repeat_greedy_min  # below range
		assert_repeat_greedy(3..5, 0, :p, mismatch(:p), :p, mismatch(:p))
	end
	def test_repeat_greedy1  # inside range
		# NOTE: this is maybe _too_ greedy.. taking the 'pattern'
		# road before taking the 'succ' road, will lead to lots of
		# backtracking.
		assert_repeat_greedy(0..1, 0, :p, :p_s, :p, mismatch(:p_s))
	end
	def test_repeat_greedy2  # inside range
		# NOTE: this is maybe _too_ greedy.. taking the 'pattern'
		# road before taking the 'succ' road, will lead to lots of
		# backtracking.
		assert_repeat_greedy(0..-1, 0, :p, :p_s, :p, mismatch(:p_s))
	end
	def test_repeat_greedy_max  # max of range
		assert_repeat_greedy(0..1, 1, :s, :s, mismatch(:s), mismatch(:s))
	end
	def test_repeat_fail1  # above range
		succ = mk_mock_node_mismatch('choice1')
		patt = mk_mock_node_mismatch('choice2')
		root = mk_repeat_lazy(succ, patt, 0, 5)
		repindex = ScannerHierarchy::RepeatGreedy::Index.new
		repindex.instance_eval '@count=6'
		context = mk_context('axx', 0, [repindex])
		root.instance_eval '@index=repindex'
		e = assert_raises(RuntimeError) { root.match(context) }
		assert_match('index.n = 6, was out of range 0..5', e.message)
	end
	def test_repeat_endless
		succ = mk_mock_node_mismatch('choice1')
		rep = mk_repeat_greedy(succ, nil, 0, -1, 0)
		patt = Test::Unit::MockObject(ScannerHierarchy::Base).new
		n = 0
		patt.set_return_values(
			# simulate a sequence of nodes where Width=Zero.
			:match => lambda do |context|
				n += 1
				puts "PAT"
				if n > 3
					raise "endless loop"
				end
				rep.match(context)  # must fail
			end
		)
		rep.set_pattern(patt)
		root = mk_slot(rep)
		context = mk_context('axx', 0, [0])
		retval = root.match(context)
		assert_equal('choice1', retval)
		assert_equal(1, n)
	end
	undef test_repeat_endless # TODO: make me work
	def test_capture1
		root = mk_capture(@node_match, 0)
		context = mk_context('axx', 1)
		input = context.input.clone
		assert_nil(context.captures[0])
		retval = root.match(context)
		assert_equal('match', retval)
		assert_equal(1, @match_context.size)
		assert_nil(context.captures[0])
		assert_equal(input, @match_context[0].captures[0])
	end
	def test_capture2
		# exercise what happens when succ fails, and things gets restored
		root = mk_capture(@node_mismatch, 0)
		context = mk_context('axx', 1)
		class << context
			def set_capture(captureid, value)
				@captures[captureid] = value
			end
		end
		context.set_capture(0, "mock input")
		input = context.input.clone
		assert_raises(Mismatch) { root.match(context) }
		assert_equal(1, @match_context.size)
		assert_equal(input, @match_context[0].captures[0])
		assert_equal('mock input', context.captures[0])
	end
	def test_last
		root = mk_last
		repindex = ScannerHierarchy::RepeatGreedy::Index.new
		stack = [repindex]
		context = mk_context('axx', 1, stack)
		assert_nil(context.found)
		root.match(context)
		assert_not_nil(context.found)
		assert_kind_of(Context, context.found)
		# confirm that cloning is taking place
		context.input_next do
			assert_not_equal(context.input, context.found.input)
		end
		assert_equal(context.input, context.found.input)
		repindex.increment do
			assert_not_equal(context.indexes, context.found.indexes)
		end
		assert_equal(context.indexes, context.found.indexes)
		# TODO: this would be a good place to exercise RepeatBase::Index.stack cloning
		context.capture_input(0) do
			assert_not_equal(context.captures, context.found.captures)
		end
		assert_equal(context.captures, context.found.captures)
	end
end

TestScannerMatch.run if $0 == __FILE__
