require 'test/unit'
require 'abstract_syntax'
require 'regex_engine'

# constraints:
# uncommenting the first line in a #setup method
# should pass the test.
class XTestRegexEngine < Test::Unit::TestCase
	include RegexFactory
	def setup_repeat1
		# return /ab*ba/
		rep = mk_repeat(mk_letter('b'))
		expr = mk_sequence(mk_letter('a'), rep, mk_letter('b'), mk_letter('a'))
		RegexEngine.new(expr)
	end
	def xtest_repeat1
		m = setup_repeat1.match("0abbba2")
		assert_equal("abbba", m.to_s) # greedy match
	end
	def setup_wildcard_greedy
		# return /x.*x/
		x1 = mk_letter('x')
		x2 = mk_letter('x')
		wild = mk_wild
		rep = mk_repeat(wild)
		seq = mk_sequence(x1, rep)
		expr = mk_sequence(seq, x2)
		RegexEngine.new(expr)
	end
	def test_wildcard_greedy1
		m = setup_wildcard_greedy.match("0x123")
		assert_equal(nil, m) # never enters an accepting state
	end
	def test_wildcard_greedy2
		m = setup_wildcard_greedy.match("0x12\n3x4")
		assert_equal(nil, m) # newline mismatches
	end
	def test_wildcard_greedy3
		m = setup_wildcard_greedy.match("0x123x4")
		assert_equal("x123x", m.to_s)
	end
	def test_wildcard_greedy4
		m = setup_wildcard_greedy.match("0x123x4x5")
		assert_equal("x123x4x", m.to_s) # greedy match
	end
	def setup_one_group
		# return /x(.*)x/
		x1 = mk_letter('x')
		x2 = mk_letter('x')
		wild = mk_wild
		rep = mk_repeat(wild)
		grp = mk_group(rep)
		seq = mk_sequence(x1, grp)
		expr = mk_sequence(seq, x2)
		RegexEngine.new(expr)
	end
	def xtest_one_group1
		m = setup_one_group.match("0x123x4")
		assert_equal(["x123x", "123"], m.to_a)
	end
	def setup_two_group
		# return /a(.*)b(.*)c/
		a = mk_letter('a')
		b = mk_letter('b')
		c = mk_letter('c')
		grp1 = mk_group(mk_repeat(mk_wild))
		grp2 = mk_group(mk_repeat(mk_wild))
		seq1 = mk_sequence(a, grp1)
		seq2 = mk_sequence(b, grp2)
		seq3 = mk_sequence(seq1, seq2)
		expr = mk_sequence(seq3, c)
		RegexEngine.new(expr)
	end
	def test_two_group1
		m = setup_two_group.match("0a123b4")
		assert_equal(nil, m)
	end
	def test_two_group2
		m = setup_two_group.match("0a123b4c5")
		assert_equal(["a123b4c", "123", "4"], m.to_a)
	end
	def setup_backref 
		# return /(Y|X).*\1/
		x = mk_letter('X')
		y = mk_letter('Y')
		grp = mk_group(mk_alternation(x, y))
		rep = mk_repeat(mk_wild)
		seq = mk_sequence(grp, rep)
		backref = mk_backref(1)
		expr = mk_sequence(seq, backref)
		RegexEngine.new(expr)
	end
	def xtest_backref1
		m = setup_backref.match("0X123Y4")
		assert_equal(nil, m)
	end
	def xtest_backref2
		m = setup_backref.match("0X123X4")
		assert_equal(["X123X", "X"], m.to_a)
	end
	def xtest_backref3
		m = setup_backref.match("0Y123Y4")
		assert_equal(["Y123Y", "Y"], m.to_a)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestRegexEngine)
end
