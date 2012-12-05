require 'test/unit'
require 'parser'

class TestParser < Test::Unit::TestCase
	include RegexFactory
	def compile(regex)
		Parser.new(regex.split(//)).expression
	end
	def test_sequence_any1
		exp = mk_sequence(mk_letter('a'), mk_wild, mk_letter('b'))
		i = compile("a.b")
		assert_equal(exp, i)
	end
	def test_sequence_group1
		grp = mk_group(mk_repeat(mk_wild, 0, -1))
		exp = mk_sequence(mk_letter('a'), grp, mk_letter('b'))
		i = compile("a(.*)b")
		assert_equal(exp, i)
	end
	def test_repeat_normal1
		rep = mk_repeat(mk_wild, 0, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.*b")
		assert_equal(exp, i)
	end
	def test_repeat_normal2
		rep = mk_repeat(mk_wild, 1, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.+b")
		assert_equal(exp, i)
	end
	def test_repeat_range1
		rep = mk_repeat(mk_wild, 22, 55)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.{22,55}b")
		assert_equal(exp, i)
	end
	def test_repeat_range2
		rep = mk_repeat(mk_wild, 4, 4, true)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.{4}?b")
		assert_equal(exp, i)
	end
	def test_repeat_range3
		rep = mk_repeat(mk_wild, 4, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.{4,}b")
		assert_equal(exp, i)
	end
	def test_repeat_range4
		rep = mk_repeat(mk_wild, 4, -1, true)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.{4,}?b")
		assert_equal(exp, i)
	end
	def test_repeat_range_legal1
		# Apparently these constructions are perfectly legal
		input = [
			"a{3",        # premature end of input
			"a{,}b",      # neither min or max specified
			"a{,3}b",     # min expected, but got none
			"a{43x3}b",   # either ',' or '}' expected, got 'x'
			"a{43,333",   # premature end of input
			"a{43,333x",  # expected '}', got 'x'
		]
		res = input.map{|str| 
			ok = false
			begin
				compile(str) 
				ok = true
			rescue RuntimeError
			end
			ok
		}
		assert_equal([true] * input.size, res)
	end
	def test_repeat_range_illegal1
		input = [
			"a{999,666}"  # expected (min <= max), got (min > max)
		]
		res = input.map{|str| 
			ok = false
			begin
				compile(str) 
			rescue RuntimeError
				ok = true
			end
			ok
		}
		assert_equal([true] * input.size, res)
	end
	def test_repeat_illegal1
		input = [
			"*a",       # nothing to repeat
			"+a",       # nothing to repeat 
			#"?a",      # nothing to repeat 
			"a(*)b",    # nothing to repeat 
			"x|*",      # nothing to repeat 
		]
		res = input.map{|str| 
			ok = false
			begin
				compile(str) 
			rescue CannotRepeat
				ok = true
			end
			ok
		}
		assert_equal([true] * input.size, res)
	end
	def test_repeat_group1
		seq = mk_sequence(mk_letter('a'), mk_letter('b'))
		exp = mk_sequence(mk_repeat(mk_group(seq), 0, -1), mk_letter('a'))
		i = compile("(ab)*a")
		assert_equal(exp, i)
	end
	def test_repeat_lazy1
		rep = mk_repeat(mk_wild, 0, -1, true)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.*?b")
		assert_equal(exp, i)
	end
	def test_group_missing_open_parentesis1
		assert_raises(RuntimeError) { compile(")") }
	end
	def test_group_missing_close_parentesis1
		assert_raises(RuntimeError) { compile("(") }
	end
	def test_alternation_normal1
		exp = mk_alternation(mk_letter('a'), mk_letter('b'))
		i = compile("a|b")
		assert_equal(exp, i)
	end
	def test_alternation_normal2
		seq1 = mk_sequence(mk_letter('a'), mk_letter('b'))
		seq2 = mk_sequence(mk_letter('c'), mk_letter('d'))
		exp = mk_alternation(seq1, seq2)
		i = compile("ab|cd")
		assert_equal(exp, i)
	end
	def test_alternation_group1
		alt = mk_alternation(mk_letter('x'), mk_letter('y'))
		exp = mk_sequence(mk_letter('a'), mk_group(alt), mk_letter('b'))
		i = compile("a(x|y)b")
		assert_equal(exp, i)
	end
	def test_alternation_group_nested1
		alt1 = mk_alternation(mk_letter('x'), mk_letter('y'))
		seq1 = mk_sequence(mk_letter('b'), mk_group(alt1), mk_letter('c'))
		alt2 = mk_alternation(mk_letter('a'), seq1, mk_letter('d'))
		exp = mk_sequence(mk_letter('0'), mk_group(alt2), mk_letter('1'))
		i = compile("0(a|b(x|y)c|d)1")
		assert_equal(exp, i)
	end
	def test_escape_backref1
		grp = mk_group(mk_alternation(mk_letter('X'), mk_letter('Y')))
		exp = mk_sequence(grp, mk_repeat(mk_wild, 0, -1), mk_backref(1))
		i = compile('(X|Y).*\1')
		assert_equal(exp, i)
	end
	def test_escape_repeat1
		exp = mk_sequence(mk_letter("a"), mk_letter('*'), mk_letter("b"))
		i = compile('a\*b')
		assert_equal(exp, i)
	end
	def test_escape_any1
		exp = mk_sequence(mk_letter("a"), mk_letter('.'), mk_letter("b"))
		i = compile('a\.b')
		assert_equal(exp, i)
	end
	def test_escape_slash1
		exp = mk_sequence(mk_letter("a"), mk_letter('\\'), mk_letter("b"))
		i = compile('a\\\\b')
		assert_equal(exp, i)
	end
	def test_escape_illegal1
		assert_raises(RuntimeError) { compile('ab\\') }
	end
	def xtest_character_class1
		cc = mk_charclass('f', 'g', 'h')
		exp = mk_sequence(mk_letter('a'), cc, mk_letter('b'))
		i = compile("a[fgh]b")
		assert_equal(exp, i)
	end
	def xtest_character_class2
		cc = mk_charclass(*('c'..'m').to_a)
		exp = mk_sequence(mk_letter('a'), cc, mk_letter('b'))
		i = compile("a[c-m]b")
		assert_equal(exp, i)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestParser)
end
