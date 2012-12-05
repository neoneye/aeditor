require 'test/unit'
require 'abstract_syntax'
require 'scanner'
require 'parser'
require 'misc'
require 'match_mixins'

class TestScanner < Test::Unit::TestCase
	include RegexFactory
	# assert_equal which ignore 'id'
	def assert_equal_marshal(expected, actual, message=nil)
		full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
		assert_block(full_message) { 
			Marshal.dump(expected) == Marshal.dump(actual) 
		}
	end
	def mk_regex(str, debug=false)
		regex_ary = str.split(//)
		tree = Parser.new(regex_ary).expression
		v = Abstract2ScannerVisitor.new
		tree.accept(v)
		res = v.result
		if debug
			puts "Regexp=/#{str}/\n"+tree.inspect
			puts res.map{|i|i.pretty}.join(" ")
		end
		res
	end
	def mk_scanner(regex, input, debug=false)
		if debug  
			puts "-"*40
			puts "Input="+input.inspect
		end
		s = Scanner.new(mk_regex(regex, debug), input.split(//), debug)
		class << s
			def res; [@position_input, @position_regex, @stack.stack] end
			attr_writer :position_input, :position_regex, :stack
			def steps(n)
				ary = []
				n.times{step; ary << res.deep_clone}
				ary
			end
			def to_a
				return [nil] unless @result
				@result.map{|i| (i == nil) ? nil : @input[i[0]..i[1]].join}
			end
		end
		s
	end
	def match(regex, input, debug=false)
		s = mk_scanner(regex, input, debug)
		s.execute
		s
	end
	def assert_regex(expected, regex, input, debug=false, message=nil)
		actual = ""
		begin
			m = match(regex, input, debug)
			actual = m.to_a
			actual = nil if actual == [nil]
		rescue => e
			actual = e
		end
		full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
		assert_block(full_message) { expected == actual }
	end
	def test_abstract2scanner_visitor
		# /(a|b).?c/
		a = mk_letter 'a'
		b = mk_letter 'b'
		alt = mk_alternation(a, b)
		wild = mk_wild
		c = mk_letter 'c'
		rep = mk_repeat wild, 0, 1
		seq = mk_sequence alt, rep, c
		s = ScannerHierarchy
		exp = [
			s::Alternation.new(true),
			s::Pattern.new(true),
			s::Match.new(a),
			s::Pattern.new(false),
			s::Pattern.new(true),
			s::Match.new(b),
			s::Pattern.new(false),
			s::Alternation.new(false),
			s::Repeat.new(true),
			s::Match.new(wild),
			s::Repeat.new(false),
			s::Match.new(c)
		]
		v = Abstract2ScannerVisitor.new
		seq.accept(v)
		assert_equal_marshal(exp, v.result)
	end
	def test_mk_regex1
		s = ScannerHierarchy
		exp = [
			s::Match.new(mk_letter('a')),
			s::Group.new(true),
			s::Repeat.new(true),
			s::Match.new(mk_wild),
			s::Repeat.new(false),
			s::Group.new(false),
			s::Match.new(mk_letter('b')),
			s::Repeat.new(true),
			s::Match.new(mk_letter('c')),
			s::Repeat.new(false)
		]
		assert_equal_marshal(exp, mk_regex("a(.*)bc*"))
	end
	def test_scanner_stack1
		s = Scanner::Stack.new
		s.push_repeat(1, 2, 3, 4)
		s.push_repeat(5, 6, 7, 8)
		s.push_alternation(9, [10])
		exp = [
			[0, [], [[1, 2, 3, 4], [5, 6, 7, 8]]],
			[9, [10], []]
		]
		assert_equal(exp, s.stack)
	end
	def test_scanner_stack2
		s = Scanner::Stack.new
		s.push_repeat(1, 2, 3, 4)
		s.push_repeat(5, 6, 7, 8)
		s.increment_repeat_length
		exp = [
			[0, [], [[1, 2, 3, 4], [5, 6, 8, 0]]]
		]
		assert_equal(exp, s.stack)
	end
	def test_scanner_stack3
		s = Scanner::Stack.new
		s.push_repeat(1, 2, 3, 4)
		s.push_repeat(5, 6, 7, 8)
		s.increment_repeat_count
		exp = [
			[0, [], [[1, 2, 3, 4], [5, 6, 7, 9]]]
		]
		assert_equal(exp, s.stack)
	end
	def test_scanner_stack4
		s = Scanner::Stack.new
		s.push_repeat(1, 2, 3, 4)
		s.push_alternation(5, [10])
		s.push_repeat(6, 7, 8, 9)
		assert_equal([5, 10], s.next_alternation!)
		exp = [
			[0, [], [[1, 2, 3, 4]]],
			[5, [], []]
		]
		assert_equal(exp, s.stack)
	end
	def test_repeat_open1
		s = mk_scanner("a*b", "x")
		s.step
		assert_equal(
			[
				0, # current position_input 
				3, # current position_regex
				[ # stack of alternation
					[ # first alternation
						0,  # position_input where alternation begins
						[], # position_regex where next regex begins 
						[[0, 1, 0, 0]]  # repeat stack
					]
				]
			], 
			s.res
		)
	end
	def test_repeat_open2
		s = mk_scanner("(a*b)*", "x")
		s.step
		assert_equal([0, 8, [[0, [], [[0, 1, 0, 0]]]]], s.res)
	end
	def test_repeat_open3
		s = mk_scanner("ab*ba", "aba")
		exp = [ 
			# 'a'
			[1, 1, [[0, [], [] ]]],
			# RepeatOpen
			[1, 4, [[0, [], [[1, 2, 0, 0]] ]]],
			# 'b'
			[2, 5, [[0, [], [[1, 2, 0, 0]] ]]],
			# 'a'
			[3, 6, [[0, [], [[1, 2, 0, 0]] ]]],
			# the end
		]
		assert_equal(exp, s.steps(4))
	end
	def test_repeat_loop1
		s = mk_scanner("ab*cd", "abba")
		s.position_input = 1
		s.position_regex = 2
		s.stack = Scanner::Stack.new.push_repeat(1, 2, 1, 0) # repeat once 
		exp = [ 
			# 'b'    one time
			[2, 3, [[0, [], [[1, 2, 1, 0]] ]]],
			# RepeatClose
			[2, 4, [[0, [], [[1, 2, 1, 1]] ]]],
		]
		assert_equal(exp, s.steps(2))
	end
	def test_repeat_loop2
		s = mk_scanner("ab*cd", "abba")
		s.position_input = 1
		s.position_regex = 2
		s.stack = Scanner::Stack.new.push_repeat(1, 2, 2, 0) # repeat twice
		exp = [ 
			# 'b'    one time
			[2, 3, [[0, [], [[1, 2, 2, 0]] ]]],
			# RepeatClose
			[2, 2, [[0, [], [[1, 2, 2, 1]] ]]],
			# 'b'    two times
			[3, 3, [[0, [], [[1, 2, 2, 1]] ]]],
			# RepeatClose
			[3, 4, [[0, [], [[1, 2, 2, 2]] ]]],
		]
		assert_equal(exp, s.steps(4))
	end
	def test_repeat_restart_on_mismatch1
		s = mk_scanner("a.*bc", "abcbc")
		s.position_input = 2
		s.position_regex = 4
		s.stack = Scanner::Stack.new.push_repeat(1, 2, 1, 1) # done repeatning once
		s.step
		assert_equal([1, 2, [[0, [], [[1, 2, 2, 0]] ]]], s.res)
	end
	def test_repeat_restart_on_mismatch2
		s = mk_scanner("a.bc", "abcbc")
		s.position_input = 2
		s.position_regex = 2
		s.stack = Scanner::Stack.new
		# there is nothing to restart, thus exception
		assert_raises(Scanner::Mismatch) { s.step }
	end
	def test_init_registers1
		s = mk_scanner("a(b(c))(d)", "")
		assert_equal([nil]*4, s.registers)
		r = s.regex
		assert_equal((1..3).to_a, [r[1].register, r[3].register, r[7].register])
		assert_equal((1..3).to_a, [r[6].register, r[5].register, r[9].register])
	end
	def test_init_registers2
		s = mk_scanner("abcd", "")
		assert_equal([nil], s.registers)
	end
	include MatchAlternation
	undef test_alternation11
	include MatchRepeat
	undef test_repeat7, test_repeat8, test_repeat9
	include MatchSequence
	include MatchDifficult
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestScanner)
end
