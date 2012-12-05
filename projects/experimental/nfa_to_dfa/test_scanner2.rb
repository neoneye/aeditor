require 'test/unit'
require 'abstract_syntax'
require 'scanner2'
require 'parser'
require 'misc'
require 'match_mixins'

class TestScanner2 < Test::Unit::TestCase
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
		v = AssignRegistersVisitor.new
		tree.accept(v)
		registers = v.register
		v = Abstract2ScannerVisitor.new
		res = tree.accept(v)
		if debug
			puts "Regexp=/#{str}/\n"+tree.inspect
			puts res.pretty
			#puts res.inspect
		end
		[res, registers]
	end
	def mk_scanner(regex, input, debug=false)
		if debug  
			puts "-"*40
			puts "Input="+input.inspect
		end 
		expr, regs = mk_regex(regex, debug)
		s = Scanner.new(expr, regs, input.split(//), debug)
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
		grp = mk_group(alt)
		wild = mk_wild
		c = mk_letter 'c'
		rep = mk_repeat wild, 0, 1
		seq = mk_sequence grp, rep, c
		s = ScannerHierarchy
		nl = s::Nil.new
		exp = s::GroupOpen.new(
			1,
			s::Alternation.new(
				[s::Match.new(a, nl), s::Match.new(b, nl)],
				s::GroupClose.new(
					1,
					s::Repeat.new(
						s::Match.new(wild, s::RepeatEnd.new),
						s::Match.new(c, s::Last.new)
					)
				)
			)
		)
		seq.accept(AssignRegistersVisitor.new)
		v = Abstract2ScannerVisitor.new
		res = seq.accept(v)
		assert_equal_marshal(exp, res)
	end
	def test_mk_regex1
		s = ScannerHierarchy
		nl = s::Nil.new
		re = s::RepeatEnd.new
		exp = s::Match.new(mk_letter('a'),
			s::GroupOpen.new(
				1,
				s::Repeat.new(
					s::Match.new(mk_wild, re),
					s::GroupClose.new(
						1,
						s::Match.new(mk_letter('b'),
							s::Repeat.new(
								s::Match.new(mk_letter('c'), re),
								s::Last.new
							)
						)
					)
				)
			)
		) 
		res = mk_regex("a(.*)bc*")
		assert_equal_marshal([exp, 2], res)
	end
	def test_init_registers1
		s = mk_scanner("a(b(c))(d)", "")
		assert_equal(4, s.number_of_registers)
		#r = s.regex
		#assert_equal((1..3).to_a, [r[1].register, r[3].register, r[7].register])
		#assert_equal((1..3).to_a, [r[6].register, r[5].register, r[9].register])
	end
	def test_init_registers2
		s = mk_scanner("abcd", "")
		assert_equal(1, s.number_of_registers)
	end
	include MatchAlternation
	include MatchSequence
	include MatchDifficult
	include MatchRepeat

	#include MatchRepeat2
	undef test_repeat_plus1
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestScanner2)
end
